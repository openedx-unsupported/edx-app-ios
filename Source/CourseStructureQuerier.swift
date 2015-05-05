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
class CourseOutlineQuerier {
    private var courseID : String
    private var courseOutline : CourseOutline?
    
    init(courseID : String, outline : CourseOutline?) {
        // TODO: Load this over the network or from disk instead of using a test stub
        self.courseID = courseID
        self.courseOutline = outline
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
                reject(NSError())
            }
        }
    }
    
    private func blockWithID(id : CourseBlockID) -> CourseBlock? {
        return courseOutline?.blocks[id]
    }
}