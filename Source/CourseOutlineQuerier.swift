//
//  CourseOutlineQuerier.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseOutlineQuerier {
    public private(set) var courseID : String
    private var interface : OEXInterface?
    private var networkManager : NetworkManager?
    private var courseOutline : Promise<CourseOutline>?
    
    public init(courseID : String, interface : OEXInterface?, networkManager : NetworkManager?) {
        // TODO: Load this over the network or from disk instead of using a test stub
        self.courseID = courseID
        self.interface = interface
        self.networkManager = networkManager
    }
    
    /// Use this to create a querier with an existing outline.
    /// Typically used for tests
    public init(courseID : String, outline : CourseOutline) {
        self.courseOutline = Promise(value : outline)
        self.courseID = courseID
        
        loadedNodes(outline.blocks)
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
    public func childrenOfBlockWithID(blockID : CourseBlockID?, forMode mode : CourseOutlineMode) -> Promise<[CourseBlock]> {
        if let outline = self.courseOutline?.value, block = self.courseOutline?.value?.blocks[blockID ?? outline.root] {
            if let blocks = block.children.mapOrFailIfNil ({ self.blockWithID($0, inOutline : outline) }) {
                let filtered = filterBlocks(blocks, forMode: mode)
                return Promise(value : filtered)
            }
        }
        
        return blockWithID(blockID).then {block in
            return when(block.children.map {
                return self.blockWithID($0)
            }).then {
                return Promise(value : self.filterBlocks($0, forMode: mode))
            }
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
    
    func flatMapRootedAtBlockWithID<A>(id : CourseBlockID, map : CourseBlock -> [A]) -> Promise<[A]> {
        loadOutlineIfNecessary()
        return courseOutline?.then {[weak self] outline -> [A] in
            var result : [A] = []
            self?.flatMapRootedAtBlockWithID(id, inOutline: outline, map: map, accumulator: &result)
            return result
        } ?? Promise(error : NSError.oex_courseContentLoadError())
    }
    
    func loadOutlineIfNecessary() {
        if courseOutline == nil || courseOutline?.error != nil {
            let request = CourseOutlineAPI.requestWithCourseID(courseID)
            courseOutline = networkManager?.promiseForRequest(request).then {[weak self] outline -> CourseOutline in
                self?.loadedNodes(outline.blocks)
                return outline
            }
        }
    }
    
    /// Loads the given block.
    /// nil means use the course root.
    public func blockWithID(id : CourseBlockID?) -> Promise<CourseBlock> {
        loadOutlineIfNecessary()
        if let outline = courseOutline?.value, block = blockWithID(id ?? outline.root, inOutline: outline) {
            return Promise(value : block)
        }
        return courseOutline?.then {outline in
            return Promise{ fulfill, reject in
                let blockID = id ?? outline.root
                if let block = self.blockWithID(blockID, inOutline : outline) {
                    fulfill(block)
                }
                else {
                    reject(NSError.oex_courseContentLoadError())
                }
            }
        } ?? Promise(error : NSError.oex_courseContentLoadError())
    }
    
    private func blockWithID(id : CourseBlockID, inOutline outline : CourseOutline) -> CourseBlock? {
        return outline.blocks[id]
    }
}