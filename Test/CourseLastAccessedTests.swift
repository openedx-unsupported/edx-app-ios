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

    func testExample() {
        
        let json = JSON(readjson("CourseStatusInfo"))
        
        if let lastAccessed = CourseLastAccessed(json : json) {
        
        let passingCondition = lastAccessed.moduleId == "i4x://edX/DemoX/html/6018785795994726950614ce7d0f38c5" && lastAccessed.modulePath.count == 5
            XCTAssertTrue(passingCondition, "Parsing Failed")
        }
        
    }
    
    func readjson(fileName: String) -> NSDictionary {
        let URL = NSBundle.mainBundle().URLForResource(fileName, withExtension: "json")!
        let jsonData = try! NSData(contentsOfURL: URL, options: NSDataReadingOptions.DataReadingMappedIfSafe)
        let jsonDict = (try! NSJSONSerialization.JSONObjectWithData(jsonData, options: [])) as! NSDictionary
        return jsonDict
    }

}
