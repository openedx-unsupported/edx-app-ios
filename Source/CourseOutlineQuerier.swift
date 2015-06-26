//
//  CourseOutlineQuerier.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


public struct BlockGroup {
    public let block : CourseBlock
    public let children : [CourseBlock]
}

private enum TraversalDirection {
    case Forward
    case Reverse
}

public class CourseOutlineQuerier : NSObject {
    public private(set) var courseID : String
    private let interface : OEXInterface?
    private let networkManager : NetworkManager?
    private let courseOutline : BackedStream<CourseOutline> = BackedStream()
    
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
                self?.courseOutline.removeBacking()
            }, failure : {[weak self] _ in
                self?.courseOutline.removeBacking()
            }
        )
    }
    
    private func loadedNodes(blocks : [CourseBlockID : CourseBlock]) {
        var videos : [OEXVideoSummary] = []
        for (blockID, block) in blocks {
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
        if courseOutline.value == nil && !courseOutline.hasBacking {
            let request = CourseOutlineAPI.requestWithCourseID(courseID)
            if let loader = networkManager?.streamForRequest(request, persistResponse: true) {
                courseOutline.backWithStream(loader)
            }
        }
    }
    
    public func spanningCursorForBlockWithID(blockID : CourseBlockID?, forMode mode : CourseOutlineMode) -> Stream<ListCursor<BlockGroup>>{
        return courseOutline.flatMap {outline in
            self.cursorForLeafGroupsAdjacentToBlockWithID(blockID ?? outline.root, forMode: mode, inOutline:outline).toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    func depthOfBlockWithID(blockID : CourseBlockID, inOutline outline : CourseOutline, fromRoot root : CourseBlockID) -> Int? {
        if blockID == root {
            return 0
        }
        else {
            return outline.blocks[root].flatMap {
                let children = $0.children
                for child in children {
                    if let depth = depthOfBlockWithID(blockID, inOutline: outline, fromRoot: child) {
                        return depth + 1
                    }
                }
                return nil
            }
        }
    }
    
    private func depthOfBlockWithID(blockID : CourseBlockID, inOutline outline : CourseOutline) -> Int? {
        return depthOfBlockWithID(blockID, inOutline: outline, fromRoot: outline.root)
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
                    if let group = childrenOfBlockWithID(next.blockID, forMode: mode, inOutline: outline) {
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
                case .Reverse: children = block.children.reverse()
                }
                
                for child in children {
                    let item = (blockID : child, depth : next.depth + 1)
                    queue.insert(item, atIndex: 0)
                }
            }
        }
        return groups
    }
    
    private func cursorForLeafGroupsAdjacentToBlockWithID(blockID : CourseBlockID, forMode mode : CourseOutlineMode, inOutline outline : CourseOutline) -> ListCursor<BlockGroup>? {
        var list : [BlockGroup] = []
        if let current = childrenOfBlockWithID(blockID, forMode: mode, inOutline: outline) {
            let before = leafGroupsFromDirection(.Forward, forBlockWithID: blockID, forMode: mode, inOutline: outline)
            let after = leafGroupsFromDirection(.Reverse, forBlockWithID: blockID, forMode: mode, inOutline: outline)
            list.extend(before)
            list.append(current)
            list.extend(after)
            return ListCursor(list: list, index: before.count)
        }
        else {
            return nil
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
    
    private func flatMapRootedAtBlockWithID<A>(id : CourseBlockID, inOutline outline : CourseOutline, map : CourseBlock -> [A], inout accumulator : [A]) {
        if let block = self.blockWithID(id, inOutline: outline) {
            accumulator.extend(map(block))
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
    public func blockWithID(id : CourseBlockID?) -> Stream<CourseBlock> {
        loadOutlineIfNecessary()
        return courseOutline.flatMap {outline in
            let blockID = id ?? outline.root
            let block = self.blockWithID(blockID, inOutline : outline)
            return block.toResult(NSError.oex_courseContentLoadError())
        }
    }
    
    private func blockWithID(id : CourseBlockID, inOutline outline : CourseOutline) -> CourseBlock? {
        return outline.blocks[id]
    }
}