//
//  CourseOutlineQuerier.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

struct BlockCompletionObserver: Equatable {
    var controller: UIViewController
    var blockID: CourseBlockID
    var delegate: BlockCompletionDelegate
    
    static func == (lhs: BlockCompletionObserver, rhs: BlockCompletionObserver) -> Bool {
        return lhs.blockID == rhs.blockID
    }
}

protocol BlockCompletionDelegate {
    func didChangeCompletion(in blockGroup: CourseOutlineQuerier.BlockGroup)
}

private enum TraversalDirection {
    case Forward
    case Reverse
}

public class CourseOutlineQuerier : NSObject {
    public struct GroupItem {
        public let block : CourseBlock
        public let nextGroup : CourseBlock?
        public let prevGroup : CourseBlock?
        public let parent : CourseBlockID
        
        init(sourceCursor : ListCursor<CourseBlock>, contextCursor : ListCursor<BlockGroup>) {
            block = sourceCursor.current
            nextGroup = sourceCursor.hasNext ? nil : contextCursor.peekNext()?.block
            prevGroup = sourceCursor.hasPrev ? nil : contextCursor.peekPrev()?.block
            parent = contextCursor.current.block.blockID
        }
    }
    
    public struct BlockGroup {
        public let block : CourseBlock
        public let children : [CourseBlock]
    }
    
    public typealias Environment = OEXConfigProvider
    private var environment : Environment?
    
    public private(set) var courseID : String
    private let enrollmentManager: EnrollmentManager?
    private var interface : OEXInterface?
    private let networkManager : NetworkManager?
    private let session : OEXSession?
    private let courseOutline : BackedStream<CourseOutline> = BackedStream()
    public var needsRefresh : Bool = false
    
    private var observers: [BlockCompletionObserver] = []
    
    func add(observer: BlockCompletionObserver) {
        observers.append(observer)
    }
    
    func remove(observer: UIViewController) {
        guard let index = observers.firstIndexMatching ({ $0.controller === observer }) else { return }
        observers.remove(at: index)
    }
    
    private var blocks: [CourseBlockID : CourseBlock] = [:] {
        didSet {
            subscribeToCompletionPropertyOnBlocks()
        }
    }
    
    public init(courseID : String, interface : OEXInterface?, enrollmentManager: EnrollmentManager?, networkManager : NetworkManager?, session : OEXSession?, environment: Environment) {
        self.courseID = courseID
        self.interface = interface
        self.enrollmentManager = enrollmentManager
        self.networkManager = networkManager
        self.session = session
        self.environment = environment
        
        super.init()
        addListener()
        addObservers()
    }
    
    /// Use this to create a querier with an existing outline.
    /// Typically used for tests
    public init(courseID : String, outline : CourseOutline) {
        self.courseOutline.backWithStream(OEXStream(value : outline))
        self.courseID = courseID
        self.enrollmentManager = nil
        self.interface = nil
        self.networkManager = nil
        self.session = nil
        
        super.init()
        addListener()
        addObservers()
    }
    
    // Use this to create a querier with interface and outline.
    // Typically used for tests
    convenience public init(courseID : String, interface : OEXInterface?, outline : CourseOutline) {
        self.init(courseID: courseID, outline: outline)
        self.interface = interface
    }
    
    private func subscribeToCompletionPropertyOnBlocks() {
        blocks.forEach { item in
            let block = item.value
            
            guard let parent = parentOfBlockWith(id: block.blockID).firstSuccess().value else { return }
            
            handleDiscussionBlockIfNeeded(parent: parent)
            
            block.isCompleted.subscribe(observer: self) { [weak self] value, _ in
                guard let weakSelf = self else { return }
                
                let allCompleted = parent.children.allSatisfy { [weak self] childID in
                    return self?.blockWithID(id: childID).firstSuccess().value?.completion ?? false
                }
                
                if allCompleted {
                    parent.completion = true
                    weakSelf.observers.forEach { observer in
                        if observer.blockID == parent.blockID {
                            let children = parent.children.compactMap { [weak self] childID in
                                return self?.blockWithID(id: childID).firstSuccess().value
                            }
                            
                            let blockGroup = BlockGroup(block: parent, children: children)
                            observer.delegate.didChangeCompletion(in: blockGroup)
                        }
                    }
                }
                
                if case CourseBlockType.Video = block.type {
                    weakSelf.handleVideoBlockIfNeeded(parent: parent)
                }
                
                if case CourseBlockType.Discussion = block.type {
                    weakSelf.handleDiscussionBlockIfNeeded(parent: parent)
                }
            }
        }
    }
    
    private func handleDiscussionBlockIfNeeded(parent: CourseBlock) {
        let allBlocksAreCompleted = parent.children.compactMap { blockWithID(id: $0).firstSuccess().value }
            .allSatisfy { $0.completion }
        
        if !allBlocksAreCompleted {
            let otherBlocks = parent.children.filter { blockID -> Bool in
                guard let childBlock = blockWithID(id: blockID).value,
                      case CourseBlockType.Discussion = childBlock.type
                else { return true }
                
                return false
            }.compactMap { blockWithID(id: $0).firstSuccess().value }
            
            let discussionBlocks = parent.children.filter { blockID -> Bool in
                guard let childBlock = blockWithID(id: blockID).value,
                      case CourseBlockType.Discussion = childBlock.type
                else { return false }
                
                return true
            }.compactMap { blockWithID(id: $0).firstSuccess().value }
            
            if !otherBlocks.isEmpty {
                let otherBlocksAreCompleted = otherBlocks.allSatisfy { $0.completion }
                
                if otherBlocksAreCompleted {
                    for block in discussionBlocks {
                        if !block.completion {
                            block.completion = true
                            break
                        }
                    }
                }
            } else {
                for block in discussionBlocks {
                    if !block.completion {
                        block.completion = true
                        break
                    }
                }
            }
        }
    }
    
    private func handleVideoBlockIfNeeded(parent: CourseBlock) {
        let childVideoBlocks = parent.children.compactMap { [weak self] item -> CourseBlock? in
            
            guard let block = self?.blockWithID(id: item, mode: .video).value else { return nil }
            
            if case CourseBlockType.Video = block.type  {
                return block
            }
            
            return nil
        }
        
        let allCompleted = childVideoBlocks.allSatisfy { $0.completion }
        
        if allCompleted {
            if !parent.completion {
                parent.completion = true
            }
            
            observers.forEach { observer in
                if observer.blockID == parent.blockID {
                    let blockGroup = BlockGroup(block: parent, children: childVideoBlocks)
                    observer.delegate.didChangeCompletion(in: blockGroup)
                }
            }
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionStarted.rawValue) { (notification, observer, _) -> Void in
            observer.needsRefresh = true
        }
    }
    
    private func addListener() {
        courseOutline.listen(self, success : {[weak self] outline in
            self?.loadedNodes(blocks: outline.blocks)
        }, failure : { _ in } )
    }
    
    private func loadedNodes(blocks: [CourseBlockID : CourseBlock]) {
        self.blocks = blocks
        
        var videos : [OEXVideoSummary] = []
        
        for (_, block) in blocks {
            switch block.type {
            case let .Video(video):
                videos.append(video)
            default:
                break
            }
        }
                
        interface?.addVideos(videos, forCourseWithID: courseID)
    }
    
    private func loadOutlineIfNecessary() {
        if (courseOutline.value == nil || needsRefresh) && !courseOutline.active {
            needsRefresh = false
            if let enrollment = enrollmentManager?.enrolledCourseWithID(courseID: courseID),
                let access = enrollment.course.courseware_access, !access.has_access {
                let stream = OEXStream<CourseOutline>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: enrollment.course.start_display_info))
                courseOutline.backWithStream(stream)
            } else {
                let request = CourseOutlineAPI.requestWithCourseID(courseID: courseID, username : session?.currentUser?.username, environment: environment as? RouterEnvironment)
                if let loader = networkManager?.streamForRequest(request, persistResponse: true) {
                    courseOutline.backWithStream(loader)
                }
            }
        }
    }
    
    public var rootID: OEXStream<CourseBlockID> {
        loadOutlineIfNecessary()
        return courseOutline.map { return $0.root }
    }
    
    public func spanningCursorForBlockWithID(blockID: CourseBlockID?, initialChildID: CourseBlockID?, forMode mode: CourseOutlineMode) -> OEXStream<ListCursor<GroupItem>> {
        loadOutlineIfNecessary()
        return courseOutline.flatMap { [weak self] outline in
            if let blockID = blockID,
                let child = initialChildID ?? self?.blockWithID(id: blockID, inOutline: outline)?.children.first,
                let groupCursor = self?.cursorForLeafGroupsAdjacentToBlockWithID(blockID: blockID, forMode: mode, inOutline: outline),
                let flatCursor = self?.flattenGroupCursor(groupCursor: groupCursor, startingAtChild: child)
            {
                return Success(v: flatCursor)
            }
            else {
                return Failure(e: NSError.oex_courseContentLoadError())
            }
        }
    }
    
    private func depthOfBlockWithID(blockID: CourseBlockID, inOutline outline: CourseOutline) -> Int? {
        var depth = 0
        var current = blockID
        while let parent = outline.parentOfBlockWithID(blockID: current), current != outline.root {
            current = parent
            depth = depth + 1
        }
        
        return depth
    }
    
    // Returns all groups before (or after if direction is .Reverse) the given block at its same tree depth
    private func leafGroupsFromDirection(direction : TraversalDirection, forBlockWithID blockID : CourseBlockID, forMode mode: CourseOutlineMode, inOutline outline : CourseOutline) -> [BlockGroup] {
        var queue : [(blockID : CourseBlockID, depth : Int)] = []
        let root = (blockID : outline.root, depth : 0)
        
        queue.append(root)
        
        let depth : Int
        if let d = depthOfBlockWithID(blockID: blockID, inOutline : outline) {
            depth = d
        }
        else {
            // block not found so just return empty
            return []
        }
        
        // Do a basic breadth first traversal
        var groups : [BlockGroup] = []
        while let next = queue.last {
            queue.removeLast()
            if next.blockID == blockID {
                break
            }
            if let block = blockWithID(id: next.blockID, inOutline: outline) {
                if next.depth == depth {
                    // Don't add groups with no children since we don't want to display them
                    if let group = childrenOfBlockWithID(blockID: next.blockID, forMode: mode, inOutline: outline), group.children.count > 0 {
                        // Account for the traversal direction. The output should always be left to right
                        switch direction {
                        case .Forward: groups.append(group)
                        case .Reverse: groups.insert(group, at:0)
                        }
                    }
                    // At the correct depth so skip all our children
                    continue
                }
                
                let children : [CourseBlockID]
                switch direction {
                case .Forward: children = block.children
                case .Reverse: children = Array(block.children.reversed())
                }
                
                for child in children {
                    let item = (blockID : child, depth : next.depth + 1)
                    queue.insert(item, at: 0)
                }
            }
        }
        return groups
    }
    
    // Turns a list of block groups into a flattened list of blocks with context information
    private func flattenGroupCursor(groupCursor : ListCursor<BlockGroup>, startingAtChild startChild: CourseBlockID) -> ListCursor<GroupItem>? {
        let cursor =
        ListCursor(list: groupCursor.current.children) {child in
            child.blockID == startChild}
            ?? ListCursor(startOfList: groupCursor.current.children)
        
        if let cursor = cursor {
            var before : [GroupItem] = []
            var after : [GroupItem] = []
            
            // Add the items from the current group
            let current = GroupItem(sourceCursor: cursor, contextCursor: groupCursor)
            let cursorBefore = ListCursor(cursor: cursor)
            cursorBefore.loopToStartExcludingCurrent {(cursor, _) in
                let item = GroupItem(sourceCursor: cursor, contextCursor: groupCursor)
                before.append(item)
            }
            let cursorAfter = ListCursor(cursor: cursor)
            cursorAfter.loopToEndExcludingCurrent {(cursor, _) in
                let item = GroupItem(sourceCursor: cursor, contextCursor: groupCursor)
                after.append(item)
            }
            
            // Now go through all the other groups
            let backCursor = ListCursor(cursor: groupCursor)
            backCursor.loopToStartExcludingCurrent {(contextCursor, _) in
                let cursor = ListCursor(endOfList: contextCursor.current.children)
                cursor?.loopToStart {(cursor, _) in
                    let item = GroupItem(sourceCursor: cursor, contextCursor: contextCursor)
                    before.append(item)
                }
            }
            
            let forwardCursor = ListCursor(cursor: groupCursor)
            forwardCursor.loopToEndExcludingCurrent {(contextCursor, _) in
                let cursor = ListCursor(startOfList: contextCursor.current.children)
                cursor?.loopToEnd {(cursor, _) in
                    let item = GroupItem(sourceCursor: cursor, contextCursor: contextCursor)
                    after.append(item)
                }
            }
            
            return ListCursor(before: Array(before.reversed()), current: current, after: after)
        }
        return nil
    }
    
    private func cursorForLeafGroupsAdjacentToBlockWithID(blockID: CourseBlockID, forMode mode: CourseOutlineMode, inOutline outline: CourseOutline) -> ListCursor<BlockGroup>? {
        if let current = childrenOfBlockWithID(blockID: blockID, forMode: mode, inOutline: outline) {
            let before = leafGroupsFromDirection(direction: .Forward, forBlockWithID: blockID, forMode: mode, inOutline: outline)
            let after = leafGroupsFromDirection(direction: .Reverse, forBlockWithID: blockID, forMode: mode, inOutline: outline)
            
            return ListCursor(before: before, current: current, after: after)
        }
        else {
            return nil
        }
    }
    
    /// for value of CourseBlockType, expected parameters are Course, Chapter, Section or Unit to iterate recursively to find parent of that type
    public func parentOfBlockWith(id blockID: CourseBlockID, type: CourseBlockType) -> OEXStream<CourseBlock> {
        loadOutlineIfNecessary()
        
        guard type == .Course || type == .Chapter || type == .Section || type == .Unit else {
            return OEXStream(error: NSError.oex_courseContentLoadError())
        }
        
        if let block = blockWithID(id: blockID).firstSuccess().value, block.type == type {
            // type of current block is the type which is passed as parameter
            return OEXStream(error: NSError.oex_courseContentLoadError())
        }
        
        guard let parentBlockID = parentOfBlockWithID(blockID: blockID).firstSuccess().value else {
            return OEXStream(error: NSError.oex_courseContentLoadError())
        }
        
        let blockStream = blockWithID(id: parentBlockID).firstSuccess()
        
        guard let value = blockStream.value else {
            return OEXStream(error: NSError.oex_courseContentLoadError())
        }
        
        return value.type == type ? blockStream : parentOfBlockWith(id: value.blockID, type: type)
    }
    
    /// parentOfBlockWith  returns Stream containing CourseBlock
    public func parentOfBlockWith(id blockID: CourseBlockID) -> OEXStream<CourseBlock> {
        loadOutlineIfNecessary()
        
        return parentOfBlockWithID(blockID: blockID).flatMap {  [weak self]  id -> Result<CourseBlock> in
            if let block = self?.blockWithID(id: id).firstSuccess().value {
                return Success(v: block)
            } else {
                return Failure(e: NSError.oex_courseContentLoadError())
            }
        }
    }
    
    /// parentOfBlockWithID returns Stream containing CourseBlockID
    public func parentOfBlockWithID(blockID: CourseBlockID) -> OEXStream<CourseBlockID?> {
        loadOutlineIfNecessary()
        
        return courseOutline.flatMap {(outline: CourseOutline) -> Result<CourseBlockID?> in
            if blockID == outline.root {
                return Success(v: nil)
            }
            else {
                if let blockID = outline.parentOfBlockWithID(blockID: blockID) {
                    return Success(v: blockID)
                } else {
                    return Failure(e: NSError.oex_courseContentLoadError())
                }
            }
        }
    }
    
    /// Loads all the children of the given block.
    /// nil means use the course root.
    public func childrenOfBlockWithID(blockID: CourseBlockID?, forMode mode: CourseOutlineMode) -> OEXStream<BlockGroup> {
        loadOutlineIfNecessary()
        
        return courseOutline.flatMap { [weak self] (outline : CourseOutline) -> Result<BlockGroup> in
            let children = self?.childrenOfBlockWithID(blockID: blockID, forMode: mode, inOutline: outline)
            return children.toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    private func childrenOfBlockWithID(blockID: CourseBlockID?, forMode mode: CourseOutlineMode, inOutline outline: CourseOutline) -> BlockGroup? {
        if let block = blockWithID(id: blockID ?? outline.root, inOutline: outline)
        {
            let blocks = block.children.compactMap({ blockWithID(id: $0, inOutline: outline) })
            let filtered = filterBlocks(blocks: blocks, forMode: mode)
            return BlockGroup(block : block, children : filtered)
        }
        else {
            return nil
        }
    }
    
    private func filterBlocks(blocks: [CourseBlock], forMode mode: CourseOutlineMode) -> [CourseBlock] {
        switch mode {
        case .full:
            return blocks
        case .video:
            return blocks.filter {(block : CourseBlock) -> Bool in
                return (block.blockCounts[CourseBlock.Category.Video.rawValue] ?? 0) > 0
            }
        }
    }
    
    private func flatMapRootedAtBlockWithID<A>(id : CourseBlockID, inOutline outline : CourseOutline, transform : (CourseBlock) -> [A], accumulator : inout [A]) {
        if let block = blockWithID(id: id, inOutline: outline) {
            accumulator.append(contentsOf: transform(block))
            for child in block.children {
                flatMapRootedAtBlockWithID(id: child, inOutline: outline, transform: transform, accumulator: &accumulator)
            }
        }
    }
    
    public func flatMapRootedAtBlockWithID<A>(id : CourseBlockID, transform : @escaping (CourseBlock) -> [A]) -> OEXStream<[A]> {
        loadOutlineIfNecessary()
        return courseOutline.map {[weak self] outline -> [A] in
            var result : [A] = []
            let blockId = id 
            self?.flatMapRootedAtBlockWithID(id: blockId, inOutline: outline, transform: transform, accumulator: &result)
            return result
        }
    }
    
    public func flatMapRootedAtBlockWithID<A>(id : CourseBlockID, transform : @escaping (CourseBlock) -> A?) -> OEXStream<[A]> {
        return flatMapRootedAtBlockWithID(id: id, transform: { block in
            return transform(block).map { [$0] } ?? []
        })
    }
    
    public func supportedBlockVideos(forCourseID id: String, blockID: String) -> OEXStream<[OEXHelperVideoDownload]> {
        let videoStream = flatMapRootedAtBlockWithID(id: blockID) { block in
            (block.type.asVideo != nil) ? block.blockID : nil
        }
        
        let blockVideos = videoStream.map({[weak self] videoIDs -> [OEXHelperVideoDownload] in
            let videos = self?.interface?.statesForVideos(withIDs: videoIDs, courseID: self?.courseID ?? "")
            return videos?.filter { video in (video.summary?.isDownloadableVideo ?? false)} ?? []
        })
        // TODO Fix me
        return blockVideos
    }
    
    /// Loads the given block.
    /// nil means use the course root.
    public func blockWithID(id: CourseBlockID?, mode: CourseOutlineMode = .full) -> OEXStream<CourseBlock> {
        loadOutlineIfNecessary()
        return courseOutline.flatMap {  [weak self]  outline in
            let blockID = id ?? outline.root
            let block = self?.blockWithID(id: blockID, inOutline: outline, forMode: mode)
            return block.toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    private func blockWithID(id: CourseBlockID, inOutline outline: CourseOutline, forMode mode: CourseOutlineMode = .full) -> CourseBlock? {
        if let block = outline.blocks[id] {
            return block
        }
        return nil
    }
}
