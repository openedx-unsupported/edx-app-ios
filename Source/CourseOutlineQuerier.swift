//
//  CourseOutlineQuerier.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseOutlineQuerier : NSObject {
    public private(set) var courseID : String
    private let interface : OEXInterface?
    private let networkManager : NetworkManager?
    private let courseOutline : BackedStream<CourseOutline> = BackedStream()
    
    public init(courseID : String, interface : OEXInterface?, networkManager : NetworkManager?) {
        // TODO: Load this over the network or from disk instead of using a test stub
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
    
    /// Loads all the children of the given block.
    /// nil means use the course root.
    public func childrenOfBlockWithID(blockID : CourseBlockID?, forMode mode : CourseOutlineMode) -> Stream<[CourseBlock]> {
        
        loadOutlineIfNecessary()
        
        return courseOutline.flatMap {[weak self] outline in
            let block = self?.blockWithID(blockID ?? outline.root, inOutline: outline)
            let blocks = block?.children.mapOrFailIfNil { self?.blockWithID($0, inOutline: outline) }
            let filtered = blocks.flatMap { self?.filterBlocks($0, forMode: mode) }
            return filtered.toResult(NSError.oex_courseContentLoadError())
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
    
    private func loadOutlineIfNecessary() {
        if courseOutline.value == nil && !courseOutline.hasBacking {
            let request = CourseOutlineAPI.requestWithCourseID(courseID)
            if let loader = networkManager?.streamForRequest(request) {
                courseOutline.backWithStream(loader)
            }
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