//
//  CourseStructureQuerier.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


// TODO: Add support for fetching the course structure from disk or network
// For now assumes it has the entire structure
public class CourseOutlineQuerier {
    private(set) var courseID : String
    private var courseOutline : CourseOutline?
    private var interface : OEXInterface?
    
    public init(courseID : String, outline : CourseOutline?, interface : OEXInterface?) {
        // TODO: Load this over the network or from disk instead of using a test stub
        self.courseID = courseID
        self.courseOutline = outline
        self.interface = interface
        
        let blocks : [CourseBlockID : CourseBlock]? = outline?.blocks
        blocks.map { self.loadedNodes($0) }
    }
    
    private func loadedNodes(blocks : [CourseBlockID : CourseBlock]) {
        for (blockID, block) in blocks {
            switch block.type {
            case let .Video(video):
                self.interface?.addVideos([video], forCourseWithID: courseID)
            default:
                break
            }
        }
    }
    
    func childrenOfBlockWithID(blockID : CourseBlockID, mode : CourseOutlineMode) -> Promise<[CourseBlock]> {
        let nodeID = blockID
        return Promise { fulfill, reject in
            let children = self.blockWithID(nodeID)?.children.mapOrFailIfNil { childID in
                self.blockWithID(childID)
            }
            // TODO: deal with modes.
            
            if let children = children {
                fulfill(children)
            }
            else {
                // TODO load data instead if possible
                reject(NSError.oex_courseContentLoadError())
            }
        }
    }
    
    func blockWithID(id : CourseBlockID) -> Promise<CourseBlock> {
        return Promise{ fulfill, reject in
            if let block = self.blockWithID(id) {
                fulfill(block)
            }
            else {
                // TODO load data if possible
                reject(NSError())
            }
        }
    }
    
    // TODO replace this with an async version
    private func blockWithID(id : CourseBlockID) -> CourseBlock? {
        return courseOutline?.blocks[id]
    }
}