//
//  JSONFormBuilder.swift
//  edX
//
//  Created by Michael Katz on 9/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class JSONFormBuilder {
    
    init(jsonFile: String) {
        if let filePath = NSBundle(forClass: self.dynamicType).pathForResource(jsonFile, ofType: "json") {
            if let data = NSData(contentsOfFile: filePath) {
                
            }
        }
        
    }
}