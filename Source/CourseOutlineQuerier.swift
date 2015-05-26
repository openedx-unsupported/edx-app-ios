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
    public func childrenOfBlockWithID(blockID : CourseBlockID?, mode : CourseOutlineMode) -> Promise<[CourseBlock]> {
        if let outline = self.courseOutline?.value, block = self.courseOutline?.value?.blocks[blockID ?? outline.root] {
            if let blocks = block.children.mapOrFailIfNil ({ self.blockWithID($0, inOutline : outline) }) {
                return Promise(value : blocks)
            }
        }
        
        return blockWithID(blockID).then {block in
            return when(block.children.map {
                return self.blockWithID($0)
            })
        }
    }
    
    func loadOutlineIfNecessary() {
        if courseOutline == nil || courseOutline?.error != nil {
            courseOutline = networkManager?.promiseForRequest(CourseOutlineAPI.requestWithCourseID(courseID))
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