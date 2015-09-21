//
//  CourseOutlineQuerier.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

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

    
    public private(set) var courseID : String
    private let interface : OEXInterface?
    private let networkManager : NetworkManager?
    private let courseOutline : BackedStream<CourseOutline> = BackedStream()
    public var needsRefresh : Bool = false
    
    public init(courseID : String, interface : OEXInterface?, networkManager : NetworkManager?) {
        self.courseID = courseID
        self.interface = interface
        self.networkManager = networkManager
        super.init()
        addListener()
    }
    
    /// Use this to create a querier with an existing outline.
    /// Typically used for tests
    public init(courseID : String, outline : CourseOutline) {
        self.courseOutline.backWithStream(Stream(value : outline))
        self.courseID = courseID
        self.interface = nil
        self.networkManager = nil
        
        super.init()
        addListener()
    }
    
    private func addListener() {
        courseOutline.listen(self,
            success : {[weak self] outline in
                self?.loadedNodes(outline.blocks)
            }, failure : { _ in
            }
        )
    }
    
    private func loadedNodes(blocks : [CourseBlockID : CourseBlock]) {
        var videos : [OEXVideoSummary] = []
        for (_, block) in blocks {
            switch block.type {
            case let .Video(video):
                videos.append(video)
            default:
                break
            }
        }
        
        self.interface?.addVideos(videos, forCourseWithID: courseID)
    }
    
    private func loadOutlineIfNecessary() {
        if (courseOutline.value == nil || needsRefresh) && !courseOutline.active {
            needsRefresh = false
            if let course = self.interface?.courseWithID(courseID),
                access = course.courseware_access
                where !access.has_access
            {
                let stream = Stream<CourseOutline>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info))
                courseOutline.backWithStream(stream)
            }
            else {
                let request = CourseOutlineAPI.requestWithCourseID(courseID)
                if let loader = networkManager?.streamForRequest(request, persistResponse: true) {
                    courseOutline.backWithStream(loader)
                }
            }
        }
    }
    
    public func spanningCursorForBlockWithID(blockID : CourseBlockID?, initialChildID : CourseBlockID?, forMode mode : CourseOutlineMode) -> Stream<ListCursor<GroupItem>> {
        loadOutlineIfNecessary()
        return courseOutline.flatMap {[weak self] outline in
            if let blockID = blockID,
                child = initialChildID ?? self?.blockWithID(blockID, inOutline: outline)?.children.first,
                groupCursor = self?.cursorForLeafGroupsAdjacentToBlockWithID(blockID, forMode: mode, inOutline: outline),
                flatCursor = self?.flattenGroupCursor(groupCursor, startingAtChild: child)
            {
                return Success(flatCursor)
            }
            else {
                return Failure(NSError.oex_courseContentLoadError())
            }
        }
    }
    
    private func depthOfBlockWithID(blockID : CourseBlockID, inOutline outline : CourseOutline) -> Int? {
        var depth = 0
        var current = blockID
        while let parent = outline.parentOfBlockWithID(current) where current != outline.root {
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
        if let d = depthOfBlockWithID(blockID, inOutline : outline) {
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
            if let block = blockWithID(next.blockID, inOutline: outline) {
                if next.depth == depth {
                    // Don't add groups with no children since we don't want to display them
                    if let group = childrenOfBlockWithID(next.blockID, forMode: mode, inOutline: outline) where group.children.count > 0 {
                        // Account for the traversal direction. The output should always be left to right
                        switch direction {
                        case .Forward: groups.append(group)
                        case .Reverse: groups.insert(group, atIndex:0)
                        }
                    }
                    // At the correct depth so skip all our children
                    continue
                }
                
                let children : [CourseBlockID]
                switch direction {
                case .Forward: children = block.children
                case .Reverse: children = Array(block.children.reverse())
                }
                
                for child in children {
                    let item = (blockID : child, depth : next.depth + 1)
                    queue.insert(item, atIndex: 0)
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
            
            return ListCursor(before: Array(before.reverse()), current: current, after: after)
        }
        return nil
    }
    
    private func cursorForLeafGroupsAdjacentToBlockWithID(blockID : CourseBlockID, forMode mode : CourseOutlineMode, inOutline outline : CourseOutline) -> ListCursor<BlockGroup>? {
        if let current = childrenOfBlockWithID(blockID, forMode: mode, inOutline: outline) {
            let before = leafGroupsFromDirection(.Forward, forBlockWithID: blockID, forMode: mode, inOutline: outline)
            let after = leafGroupsFromDirection(.Reverse, forBlockWithID: blockID, forMode: mode, inOutline: outline)
            
            return ListCursor(before: before, current: current, after: after)
        }
        else {
            return nil
        }
    }
    
    public func parentOfBlockWithID(blockID : CourseBlockID) -> Stream<CourseBlockID?> {
        loadOutlineIfNecessary()
        
        return courseOutline.flatMap {(outline : CourseOutline) -> Result<CourseBlockID?> in
            if blockID == outline.root {
                return Success(nil)
            }
            else {
                if let blockID = outline.parentOfBlockWithID(blockID) {
                    return Success(blockID)
                }
                else {
                    return Failure(NSError.oex_courseContentLoadError())
                }
                
            }
        }
    }
    
    /// Loads all the children of the given block.
    /// nil means use the course root.
    public func childrenOfBlockWithID(blockID : CourseBlockID?, forMode mode : CourseOutlineMode) -> Stream<BlockGroup> {
        
        loadOutlineIfNecessary()
        
        return courseOutline.flatMap {[weak self] (outline : CourseOutline) -> Result<BlockGroup> in
            let children = self?.childrenOfBlockWithID(blockID, forMode: mode, inOutline: outline)
            return children.toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    private func childrenOfBlockWithID(blockID : CourseBlockID?, forMode mode : CourseOutlineMode, inOutline outline : CourseOutline) -> BlockGroup? {
        if let block = self.blockWithID(blockID ?? outline.root, inOutline: outline),
            blocks = block.children.mapOrFailIfNil({ self.blockWithID($0, inOutline: outline) })
        {
            let filtered = self.filterBlocks(blocks, forMode: mode)
            return BlockGroup(block : block, children : filtered)
        }
        else {
            return nil
        }
    }
    
    private func filterBlocks(blocks : [CourseBlock], forMode mode : CourseOutlineMode) -> [CourseBlock] {
        switch mode {
        case .Full:
            return blocks
        case .Video:
            return blocks.filter {(block : CourseBlock) -> Bool in
                return (block.blockCounts[CourseBlock.Category.Video.rawValue] ?? 0) > 0
            }
        }
    }
    
    private func filterBlock(block : CourseBlock, forMode mode : CourseOutlineMode) -> CourseBlock? {
        switch mode {
        case .Full:
            return block
        case .Video:
            return (block.blockCounts[CourseBlock.Category.Video.rawValue] ?? 0) > 0 ? block : nil
        }
    }
    
    private func flatMapRootedAtBlockWithID<A>(id : CourseBlockID, inOutline outline : CourseOutline, map : CourseBlock -> [A], inout accumulator : [A]) {
        if let block = self.blockWithID(id, inOutline: outline) {
            accumulator.appendContentsOf(map(block))
            for child in block.children {
                flatMapRootedAtBlockWithID(child, inOutline: outline, map: map, accumulator: &accumulator)
            }
        }
    }
    

    public func flatMapRootedAtBlockWithID<A>(id : CourseBlockID, map : CourseBlock -> [A]) -> Stream<[A]> {
        loadOutlineIfNecessary()
        return courseOutline.map {[weak self] outline -> [A] in
            var result : [A] = []
            let blockId = id ?? outline.root
            self?.flatMapRootedAtBlockWithID(blockId, inOutline: outline, map: map, accumulator: &result)
            return result
        }
    }
    
    /// Loads the given block.
    /// nil means use the course root.
    public func blockWithID(id : CourseBlockID?, mode : CourseOutlineMode = .Full) -> Stream<CourseBlock> {
        loadOutlineIfNecessary()
        return courseOutline.flatMap {outline in
            let blockID = id ?? outline.root
            let block = self.blockWithID(blockID, inOutline : outline, forMode : mode)
            return block.toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    private func blockWithID(id : CourseBlockID, inOutline outline : CourseOutline, forMode mode : CourseOutlineMode = .Full) -> CourseBlock? {
        if let block = outline.blocks[id] {
            return filterBlock(block, forMode: mode)
        }
        return nil
    }
}