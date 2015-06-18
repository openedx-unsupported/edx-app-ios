//
//  CourseLastAccessedTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 17/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

class CourseLastAccessedTests: XCTestCase {

    func testJsonParsing() {
        
        let json = JSON(readjson("CourseStatusInfo"))
        
        if let lastAccessed = CourseLastAccessed(json : json) {
        
        let passingCondition = lastAccessed.moduleId == "i4x://edX/DemoX/html/6018785795994726950614ce7d0f38c5" && count(lastAccessed.modulePath) == 5
            XCTAssertTrue(passingCondition, "Parsing Failed")
        }
        
    }
    
    func readjson(fileName: String) -> NSDictionary {
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "json")
        let jsonData = NSData(contentsOfMappedFile: path!)
        let jsonDict = NSJSONSerialization.JSONObjectWithData(jsonData!, options: nil, error: nil) as! NSDictionary
        return jsonDict
    }

}
