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
    public let moduleId : String
    public var modulePath = [String]() 
    //The name of the module
    public var moduleName : String?
    
    public init?(json:JSON) {
        if let module_id = json["last_visited_module_id"].string, let modulePathArray = json["last_visited_module_path"].array?.mapOrFailIfNil({$0.string})  {
            self.moduleId = module_id
            self.modulePath = modulePathArray
        }
        else {
            return nil
        }
    }
    
    public init(moduleId : String, moduleName : String!) {
        self.moduleId = moduleId
        self.moduleName = moduleName
    }
    
}
