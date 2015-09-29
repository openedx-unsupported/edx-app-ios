//
//  JSONFormBuilder.swift
//  edX
//
//  Created by Michael Katz on 9/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class JSONFormBuilder {
    
    let json: JSON
    
    init?(jsonFile: String) throws {
        if let filePath = NSBundle(forClass: self.dynamicType).pathForResource(jsonFile, ofType: "json") {
            if let data = NSData(contentsOfFile: filePath) {
                var error: NSError?
                json = JSON(data: data, error: &error)
                if error != nil { throw error! }
            } else {
                json = JSON(NSNull())
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: nil)
            }
        }  else {
            json = JSON(NSNull())
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
    }
    
    init(json: JSON) {
        self.json = json
    }
    
    
}