//
//  OEXCourseTests.swift
//  edX
//
//  Created by Akiva Leffert on 8/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

class OEXCourseTests: XCTestCase {

    func testStartOld() {
        let date = NSDate().dateByAddingTimeInterval(-1000)
        let course = OEXCourse(dictionary: [
            "start" : OEXDateFormatting.serverStringWithDate(date)
            ])
        XCTAssertTrue(course.isStartDateOld)
    }
    
    func testStartNotOld() {
        let date = NSDate().dateByAddingTimeInterval(1000)
        let course = OEXCourse(dictionary: [
            "start" : OEXDateFormatting.serverStringWithDate(date)
            ])
        XCTAssertFalse(course.isStartDateOld)
    }
    
    func testEndOld() {
        let date = NSDate().dateByAddingTimeInterval(-1000)
        let course = OEXCourse(dictionary: [
            "end" : OEXDateFormatting.serverStringWithDate(date)
            ])
        XCTAssertTrue(course.isEndDateOld)
    }
    
    func testEndNotOld() {
        let date = NSDate().dateByAddingTimeInterval(1000)
        let course = OEXCourse(dictionary: [
            "end" : OEXDateFormatting.serverStringWithDate(date)
            ])
        XCTAssertFalse(course.isEndDateOld)
    }
    
}
