//
//  CourseLastAccessedTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 17/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest

import edXCore
import edX

class CourseLastAccessedTests: XCTestCase {

    func testExample() {
        
        let json = JSON(resourceNamed : "CourseStatusInfo")
        
        if let lastAccessed = CourseLastAccessed(json : json) {
        
        let passingCondition = lastAccessed.moduleId == "i4x://edX/DemoX/html/6018785795994726950614ce7d0f38c5" && lastAccessed.modulePath.count == 5
            XCTAssertTrue(passingCondition, "Parsing Failed")
        }
        
    }
}
