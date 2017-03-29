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
        
        let testDate = Date()
        let convertedDate = OEXDateFormatting.serverStringWithDate(testDate)
        let revertedDate = OEXDateFormatting.dateWithServerString(convertedDate)
        
        //Using description explicitly as a hack for invalid NSDate comparison
        let isRevertedSuccesfully = revertedDate.description == testDate.description
        
        XCTAssertTrue(isRevertedSuccesfully, "The reverted date doesn't match the original date")
    }

    func testUserFacingTimeForPosts() {
        let currentDate = Date()

        let dateLesserThanSevenDaysOld = Date(timeInterval: -(60*60*24*3), since: currentDate)
        let dateMoreThanSevenDaysOld = Date(timeInterval: -(60*60*24*8), since: currentDate)
        
        let localizedStringForSpan = dateLesserThanSevenDaysOld.timeAgoSinceDate(currentDate)
        
        XCTAssertTrue(dateLesserThanSevenDaysOld.displayDate == localizedStringForSpan, "The dates \(dateLesserThanSevenDaysOld.displayDate),\(localizedStringForSpan) AND/OR format doesn't match")
        XCTAssertTrue(dateMoreThanSevenDaysOld.displayDate == OEXDateFormatting.formatAsDateMonthYearStringWithDate(dateMoreThanSevenDaysOld), "The dates \(dateLesserThanSevenDaysOld.displayDate), \(OEXDateFormatting.formatAsDateMonthYearStringWithDate(dateMoreThanSevenDaysOld)) AND/OR the formats don't match ")
        
    }
}
