//
//  CouseLastAccessed.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public struct CourseLastAccessed {
    public let moduleId : String
    public var modulePath = [String]() 
    //The name of the module
    public var moduleName : String?
    
    public init?(json:JSON) {
        if let module_id = json["last_visited_module_id"].string {
            self.moduleId = module_id
            
            for (index: String, subJson: JSON) in json["last_visited_module_path"] {
                self.modulePath.append(subJson.string!)
            }
        }
        else {
            return nil
        }
    }
    
    init(moduleId : String, moduleName : String!) {
        self.moduleId = moduleId
        self.moduleName = moduleName
    }
    
}