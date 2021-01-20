//
//  CouseLastAccessed.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public struct CourseLastAccessed {
    public let moduleId: String
    public var modulePath = [String]() 
    //The name of the module
    public var moduleName: String?
    
    public var lastVisitedBlockID: String = ""
    
    private enum Keys: String, RawStringExtractable {
        case moduleID = "last_visited_module_id"
        case modulePath = "last_visited_module_path"
        case lastVisitedBlockID = "last_visited_block_id"
    }
    
    public init?(json: JSON) {
        lastVisitedBlockID = json[Keys.lastVisitedBlockID].string ?? ""
        
        if let moduleID = json[Keys.moduleID].string,
           let modulePath = json[Keys.modulePath].array?.mapOrFailIfNil({$0.string}) {
            self.moduleId = moduleID
            self.modulePath = modulePath
        } else {
            return nil
        }
    }
    
    public init(moduleId : String, moduleName : String!) {
        self.moduleId = moduleId
        self.moduleName = moduleName
    }
}
