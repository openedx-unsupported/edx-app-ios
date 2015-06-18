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

class OEXDateFormattingTests: XCTestCase {

    
    let testDate = NSDate()
    


    func testConvertAndRevertTime() {
        
        let convertedDate = OEXDateFormatting.serverStringWithDate(testDate)
        let revertedDate = OEXDateFormatting.dateWithServerString(convertedDate)
        
        //Using description explicitly as a hack for invalid NSDate comparison
        let isRevertedSuccesfully = revertedDate.description == testDate.description
        
        XCTAssertTrue(isRevertedSuccesfully, "The reverted date doesn't match the original date")
    }

}
