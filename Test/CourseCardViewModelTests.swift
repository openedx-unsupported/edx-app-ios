//
//  CourseCardViewModelTests.swift
//  edX
//
//  Created by Akiva Leffert on 11/5/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX

class CourseCardViewModelTests: XCTestCase {
    
    func testStartingCourseDisplayDate() {
        func assertDisplayDate(displayDate: String?, expected: String) {
            let startInfo = OEXCourseStartDisplayInfo(date: NSDate.distantFuture(), displayDate: displayDate, type: .String)
            let course = OEXCourse.freshCourse(startInfo: startInfo, end: NSDate.distantFuture())
            XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expected))
        }
        assertDisplayDate(nil, expected: Strings.soon)
        assertDisplayDate("The future", expected: "The future")
    }
    
    func testStartingCourseTimestamp() {
        func assertDisplayTimestamp(date: NSDate?, expected: String) {
            let startInfo = OEXCourseStartDisplayInfo(date: date, displayDate: nil, type: .Timestamp)
            let course = OEXCourse.freshCourse(startInfo: startInfo, end: NSDate.distantFuture())
            XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expected))
        }
        
        let date = NSDate().dateByAddingDays(1)
        assertDisplayTimestamp(date, expected: OEXDateFormatting.formatAsMonthDayString(date))
        assertDisplayTimestamp(nil, expected: Strings.soon)
    }
    
    func testStartingCourseNoInfo() {
        let startInfo = OEXCourseStartDisplayInfo(date: NSDate.distantFuture(), displayDate: "The future", type: .None)
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: NSDate.distantFuture())
        XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: Strings.soon))
    }
    
    func testActive() {
        let startInfo = OEXCourseStartDisplayInfo(date: NSDate.distantPast(), displayDate: nil, type: .None)
        let endDate = NSDate().dateByAddingDays(1)
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: endDate)
        XCTAssertEqual(course.nextRelevantDate, Strings.courseEnding(endDate: OEXDateFormatting.formatAsMonthDayString(endDate)))
    }
    
    func testEnded() {
        let startInfo = OEXCourseStartDisplayInfo(date: NSDate.distantPast(), displayDate: nil, type: .None)
        let endDate = NSDate.distantPast()
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: endDate)
        XCTAssertEqual(course.nextRelevantDate, Strings.courseEnded(endDate: OEXDateFormatting.formatAsMonthDayString(endDate)))
    }

}
