//
//  ResumeCourseBlockTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 17/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest

import edXCore
import edX

class ResumeCourseBlockTests: XCTestCase {

    func testExample() {
        
        let json = JSON(resourceNamed : "CourseStatusInfo")
        
        if let resumeCourseItem = ResumeCourseItem(json : json) {
            let passingCondition = resumeCourseItem.lastVisitedBlockID == "i4x://edX/DemoX/html/6018785795994726950614ce7d0f38c5"
            XCTAssertTrue(passingCondition, "Parsing Failed")
        }
    }
}
