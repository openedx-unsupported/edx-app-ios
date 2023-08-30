//
//  ResumeCourseItem.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
@testable import edX
public struct ResumeCourseItem {
    public var lastVisitedBlockID: String = ""
    public var lastVisitedBlockName: String = ""
    
    private enum Keys: String, RawStringExtractable {
        case lastVisitedBlockID = "last_visited_block_id"
    }
    
    public init?(json: JSON) {
        lastVisitedBlockID = json[Keys.lastVisitedBlockID].string ?? ""
    }
    
    public init(lastVisitedBlockID: String, lastVisitedBlockName: String) {
        self.lastVisitedBlockID = lastVisitedBlockID
        self.lastVisitedBlockName = lastVisitedBlockName
    }
}
