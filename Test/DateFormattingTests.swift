//
//  OEXDateFormattingTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

class DateFormattingTests: XCTestCase {
    
    func testConvertAndRevertTime() {
        
        let testDate = NSDate()
        let convertedDate = OEXDateFormatting.serverStringWithDate(testDate)
        let revertedDate = OEXDateFormatting.dateWithServerString(convertedDate)
        
        //Using description explicitly as a hack for invalid NSDate comparison
        let isRevertedSuccesfully = revertedDate.description == testDate.description
        
        XCTAssertTrue(isRevertedSuccesfully, "The reverted date doesn't match the original date")
    }

    func testUserFacingTimeForPosts() {
        let currentDate = NSDate()

        let dateLesserThanSixDaysOld = NSDate(timeInterval: -(60*60*24*3), sinceDate: currentDate)
        let dateMoreThanSixDaysOld = NSDate(timeInterval: -(60*60*24*7), sinceDate: currentDate)
        
        let localizedStringForSpan = dateLesserThanSixDaysOld.timeAgoSinceDate(currentDate)
        
        XCTAssertTrue(dateLesserThanSixDaysOld.displayDate == localizedStringForSpan, "The dates \(dateLesserThanSixDaysOld.displayDate),\(localizedStringForSpan) AND/OR format doesn't match")
        XCTAssertTrue(dateMoreThanSixDaysOld.displayDate == OEXDateFormatting.formatAsDateMonthYearStringWithDate(dateMoreThanSixDaysOld), "The dates \(dateLesserThanSixDaysOld.displayDate), \(OEXDateFormatting.formatAsDateMonthYearStringWithDate(dateMoreThanSixDaysOld)) AND/OR the formats don't match ")
        
    }
}
