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
        func assertDisplayDate(_ displayDate: String?, expected: String) {
            let startInfo = OEXCourseStartDisplayInfo(date: Date.distantFuture(), displayDate: displayDate, type: .String)
            let course = OEXCourse.freshCourse(startInfo: startInfo, end: Date.distantFuture())
            XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expected))
        }
        assertDisplayDate(nil, expected: Strings.soon)
        assertDisplayDate("The future", expected: "The future")
    }
    
    func testStartingCourseTimestamp() {
        func assertDisplayTimestamp(_ date: Date?, expected: String) {
            let startInfo = OEXCourseStartDisplayInfo(date: date, displayDate: nil, type: .Timestamp)
            let course = OEXCourse.freshCourse(startInfo: startInfo, end: Date.distantFuture())
            XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expected))
        }
        
        let date = Date().dateByAddingDays(1)
        assertDisplayTimestamp(date, expected: OEXDateFormatting.formatAsMonthDayString(date))
        assertDisplayTimestamp(nil, expected: Strings.soon)
    }
    
    func testStartingCourseNoInfo() {
        let startInfo = OEXCourseStartDisplayInfo(date: Date.distantFuture(), displayDate: "The future", type: .None)
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: Date.distantFuture())
        XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: Strings.soon))
    }
    
    func testActive() {
        let startInfo = OEXCourseStartDisplayInfo(date: Date.distantPast(), displayDate: nil, type: .None)
        let endDate = Date().dateByAddingDays(1)
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: endDate)
        XCTAssertEqual(course.nextRelevantDate, Strings.courseEnding(endDate: OEXDateFormatting.formatAsMonthDayString(endDate)))
    }
    
    func testEnded() {
        let startInfo = OEXCourseStartDisplayInfo(date: Date.distantPast(), displayDate: nil, type: .None)
        let endDate = Date.distantPast
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: endDate)
        XCTAssertEqual(course.nextRelevantDate, Strings.courseEnded(endDate: OEXDateFormatting.formatAsMonthDayString(endDate)))
    }
    
    func testTimeZoneDates() {
        let argentinaTimeZone = TimeZone(identifier: "America/Argentina/Buenos_Aires")!
        func setUpDate() -> Date {
            let date = Date().dateByAddingDays(2)
            var utcCalendar = (Calendar.current as NSCalendar).copy() as! Calendar
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            return utcCalendar.startOfDayForDate(date)
        }
        func setUpCourseWithDate(_ date: NSDate) -> OEXCourse {
            let startInfo = OEXCourseStartDisplayInfo(date: date, displayDate: nil, type: .Timestamp)
            return OEXCourse.freshCourse(startInfo: startInfo, end: NSDate.distantFuture())
        }
        func setUpExpectedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeZone = argentinaTimeZone
            formatter.dateFormat = "MMMM dd"
            return formatter.string(from: date).uppercased()
        }
        
        let startOfDate = setUpDate()
        let course = setUpCourseWithDate(startOfDate)
        let expectedDate = setUpExpectedDate(startOfDate)
        
        NSTimeZone.setDefaultTimeZone(TimeZone(identifier: "UTC")!)
        XCTAssertNotEqual(course.nextRelevantDate, Strings.starting(startDate: expectedDate))
        NSTimeZone.setDefaultTimeZone(argentinaTimeZone)
        XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expectedDate))
    }

}
