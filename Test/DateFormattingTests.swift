//
//  DateFormattingTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import XCTest
@testable import edX



class DateFormattingTests: XCTestCase {
    
    private var actualLocalTimeZone: TimeZone = TimeZone.ReferenceType.default
    
    func testZero() {
        XCTAssertEqual("00:00", DateFormatting.formatSeconds(asVideoLength: 0))
    }
    
    func testUnderHour() {
        XCTAssertEqual("59:59", DateFormatting.formatSeconds(asVideoLength: 61 * 59))
    }
    
    func testOverHour() {
        XCTAssertEqual("01:00:00", DateFormatting.formatSeconds(asVideoLength: 60 * 60))
    }
    
    func testLong() {
        XCTAssertEqual("35:00:10", DateFormatting.formatSeconds(asVideoLength: 60 * 60 * 35 + 10))
    }
    
    func testValidDateString() {
        let date = DateFormatting.date(withServerString: "2014-11-06T20:16:45Z")
        TimeZone.ReferenceType.default = TimeZone(abbreviation: "GMT")!
        let components = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)?.components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day, NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second], from: date! as Date)

        XCTAssertEqual(components?.year, 2014)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 6)
        XCTAssertEqual(components?.hour, 20)
        XCTAssertEqual(components?.minute, 16)
        XCTAssertEqual(components?.second, 45)
    }
    
    func testValidDateStringMicroseconds() {
        let date = DateFormatting.date(withServerString: "2014-11-06T20:16:45.232333Z")
        TimeZone.ReferenceType.default = TimeZone(abbreviation: "GMT")!
        let components = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)?.components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day, NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second], from: date! as Date)
        
        XCTAssertEqual(components?.year, 2014)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 6)
        XCTAssertEqual(components?.hour, 20)
        XCTAssertEqual(components?.minute, 16)
        XCTAssertEqual(components?.second, 45)
    }
    
    func testConvertAndRevertTime() {
        
        let testDate = NSDate()
        let convertedDate = DateFormatting.serverString(withDate: testDate)
        let revertedDate = DateFormatting.date(withServerString: convertedDate)
        
        //Using description explicitly as a hack for invalid NSDate comparison
        let isRevertedSuccesfully = revertedDate?.description == testDate.description
        
        XCTAssertTrue(isRevertedSuccesfully, "The reverted date doesn't match the original date")
    }

    func testUserFacingTimeForPosts() {
        let currentDate = Date()

        let dateLesserThanSevenDaysOld = NSDate(timeInterval: -(60*60*24*3), since: currentDate)
        let dateMoreThanSevenDaysOld = NSDate(timeInterval: -(60*60*24*8), since: currentDate)
        
        let localizedStringForSpan = dateLesserThanSevenDaysOld.timeAgo(since: currentDate)
        
        XCTAssertTrue(dateLesserThanSevenDaysOld.displayDate == localizedStringForSpan, "The dates \(dateLesserThanSevenDaysOld.displayDate),\(localizedStringForSpan ?? "") AND/OR format doesn't match")
        XCTAssertTrue(dateMoreThanSevenDaysOld.displayDate == DateFormatting.format(asDateMonthYearString: dateMoreThanSevenDaysOld), "The dates \(dateLesserThanSevenDaysOld.displayDate), \(DateFormatting.format(asDateMonthYearString: dateMoreThanSevenDaysOld)) AND/OR the formats don't match ")
        
    }
    
    override func tearDown() {
        super.setUp()
        TimeZone.ReferenceType.default = actualLocalTimeZone
    }
}
