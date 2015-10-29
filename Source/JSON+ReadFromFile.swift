//
//  JSON+ReadFromFile.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public extension JSON {
    
    public init(resourceWithName fileName: String) {
        let URL = NSBundle.mainBundle().URLForResource(fileName, withExtension: "json")!
        let jsonData = try! NSData(contentsOfURL: URL, options: NSDataReadingOptions.DataReadingMappedIfSafe)
        let jsonDict = (try! NSJSONSerialization.JSONObjectWithData(jsonData, options: [])) as! NSDictionary
        self.init(jsonDict)
    }

}