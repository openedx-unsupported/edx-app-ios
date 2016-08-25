//
//  OEXColorsTests.swift
//  edX
//
//  Created by Danial Zahid on 8/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import edX
import XCTest

class OEXColorsTests: XCTestCase {
    
    var oexColors : OEXColors {
        return OEXColors.sharedInstance
    }
    
    func testColorFileExistence() {
        let filePath : String? = NSBundle.mainBundle().pathForResource("colors", ofType: "json")
        XCTAssertNotNil(filePath)
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(filePath ?? ""))
    }
    
    func testColorParsing() {
        XCTAssertNotNil(oexColors.colorForIdentifier("primaryBaseColor"))
        XCTAssertNotNil(oexColors.colorForIdentifier("primaryLightColor"))
        XCTAssertNotNil(oexColors.colorForIdentifier("primaryBaseColor", alpha: 0.5))
        XCTAssertNotNil(oexColors.colorForIdentifier("primaryLightColor", alpha: 1.0))
        XCTAssertEqual(oexColors.colorForIdentifier("primaryBaseColor"), oexColors.colorForIdentifier("primaryBaseColor", alpha: 1.0))
    }

}
