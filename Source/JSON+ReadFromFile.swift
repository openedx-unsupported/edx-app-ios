//
//  JSON+ReadFromFile.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public extension JSON {
    
    public init(resourceWithName fileName: String) {
        
        var jsonData : NSData?
        
        if let URL = NSBundle.mainBundle().URLForResource(fileName, withExtension: "json") {
            jsonData = try? NSData(contentsOfURL: URL, options: NSDataReadingOptions.DataReadingMappedIfSafe)
            assert(jsonData != nil, "Couldn't load data from file")
        }
        
        var jsonDict : NSDictionary?
        if let data = jsonData {
            jsonDict = (try? NSJSONSerialization.JSONObjectWithData(data, options: [])) as? NSDictionary
            assert(jsonDict != nil, "Couldn't parse JSON from data")
        }
        
        self.init(jsonDict ?? [:])
    }

}