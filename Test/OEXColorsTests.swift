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
    
    func testColorDataFactory() {
        oexColors.fallbackColors()
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.PrimaryBaseColor))
    }
    
    func testColorParsing() {
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.PrimaryBaseColor))
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.PrimaryLightColor))
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.PrimaryBaseColor, alpha: 0.5))
        XCTAssertNotNil(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.PrimaryLightColor, alpha: 1.0))
        XCTAssertEqual(oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.PrimaryBaseColor), oexColors.colorForIdentifier(OEXColors.ColorsIdentifiers.PrimaryBaseColor, alpha: 1.0))
    }

}
