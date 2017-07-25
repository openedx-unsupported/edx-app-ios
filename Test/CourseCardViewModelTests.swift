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
            let startInfo = OEXCourseStartDisplayInfo(date: Date.distantFuture, displayDate: displayDate, type: .string)
            let course = OEXCourse.freshCourse(startInfo: startInfo, end: Date.distantFuture as NSDate)
            XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expected))
        }
        assertDisplayDate(nil, expected: Strings.soon)
        assertDisplayDate("The future", expected: "The future")
    }
    
    func testStartingCourseTimestamp() {
        func assertDisplayTimestamp(_ date: Date?, expected: String) {
            let startInfo = OEXCourseStartDisplayInfo(date: date, displayDate: nil, type: .timestamp)
            let course = OEXCourse.freshCourse(startInfo: startInfo, end: Date.distantFuture as NSDate)
            XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expected))
        }
        
        let date = NSDate().addingDays(1)
        assertDisplayTimestamp(date, expected: DateFormatting.format(asMonthDayString: date! as NSDate)!)
        assertDisplayTimestamp(nil, expected: Strings.soon)
    }
    
    func testStartingCourseNoInfo() {
        let startInfo = OEXCourseStartDisplayInfo(date: Date.distantFuture, displayDate: "The future", type: .none)
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: NSDate.distantFuture as NSDate)
        XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: Strings.soon))
    }
    
    func testActive() {
        let startInfo = OEXCourseStartDisplayInfo(date: Date.distantPast, displayDate: nil, type: .none)
        let endDate = NSDate().addingDays(1)
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: endDate! as NSDate)
        XCTAssertEqual(course.nextRelevantDate, Strings.courseEnding(endDate: DateFormatting.format(asMonthDayString: endDate! as NSDate)!))
    }
    
    func testEnded() {
        let startInfo = OEXCourseStartDisplayInfo(date: Date.distantPast, displayDate: nil, type: .none)
        let endDate = NSDate.distantPast
        let course = OEXCourse.freshCourse(startInfo: startInfo, end: endDate as NSDate)
        XCTAssertEqual(course.nextRelevantDate, Strings.courseEnded(endDate: DateFormatting.format(asMonthDayString: endDate as NSDate)!))
    }
    
    func testTimeZoneDates() {
        let argentinaTimeZone = TimeZone(identifier: "America/Argentina/Buenos_Aires")!
        func setUpDate() -> Date {
            let date = NSDate().addingDays(2)
            var utcCalendar = (Calendar.current as NSCalendar).copy() as! Calendar
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            return utcCalendar.startOfDay(for: date!)
        }
        func setUpCourseWithDate(_ date: NSDate) -> OEXCourse {
            let startInfo = OEXCourseStartDisplayInfo(date: date as Date, displayDate: nil, type: .timestamp)
            return OEXCourse.freshCourse(startInfo: startInfo, end: NSDate.distantFuture as NSDate)
        }
        func setUpExpectedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeZone = argentinaTimeZone
            formatter.dateFormat = "MMMM dd"
            return formatter.string(from: date).uppercased()
        }
        
        let startOfDate = setUpDate()
        let course = setUpCourseWithDate(startOfDate as NSDate)
        let expectedDate = setUpExpectedDate(startOfDate)
        
        NSTimeZone.default = TimeZone(identifier: "UTC")!
        XCTAssertNotEqual(course.nextRelevantDate, Strings.starting(startDate: expectedDate))
        NSTimeZone.default = argentinaTimeZone
        XCTAssertEqual(course.nextRelevantDate, Strings.starting(startDate: expectedDate))
    }

}
