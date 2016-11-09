//
//  OEXColorsTests.swift
//  edX
//
//  Created by Danial Zahid on 8/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import edX
import XCTest

enum ColorsIdentifiers: Int {
    case PrimaryXDarkColor = 1, PrimaryDarkColor, PrimaryBaseColor, PrimaryLightColor, PrimaryXLightColor
}

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
        XCTAssertNotNil(oexColors.colorForIdentifier(ColorsIdentifiers.PrimaryBaseColor.rawValue))
        XCTAssertNotNil(oexColors.colorForIdentifier(ColorsIdentifiers.PrimaryLightColor.rawValue))
        XCTAssertNotNil(oexColors.colorForIdentifier(ColorsIdentifiers.PrimaryBaseColor.rawValue, alpha: 0.5))
        XCTAssertNotNil(oexColors.colorForIdentifier(ColorsIdentifiers.PrimaryLightColor.rawValue, alpha: 1.0))
        XCTAssertEqual(oexColors.colorForIdentifier(ColorsIdentifiers.PrimaryBaseColor.rawValue), oexColors.colorForIdentifier(ColorsIdentifiers.PrimaryBaseColor.rawValue, alpha: 1.0))
    }

}
