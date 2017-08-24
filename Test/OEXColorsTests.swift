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
        let filePath : String? = Bundle.main.path(forResource: "colors", ofType: "json")
        XCTAssertNotNil(filePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath ?? ""))
    }
    
    func testButtonsColorFileExistence() {
        let filePath : String? = Bundle.main.path(forResource: "buttons-colors", ofType: "json")
        XCTAssertNotNil(filePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath ?? ""))
    }
    
    func testColorDataFactory() {
        oexColors.fallbackColors()
        XCTAssertNotNil(oexColors.color(forIdentifier: OEXColors.ColorsIdentifiers.PrimaryBaseColor))
    }
    
    func testButtonColorDataFactory() {
        oexColors.fallbackButtonsColor()
        XCTAssertNotNil(oexColors.buttonColor(forIdentifier: OEXColors.ButtonsIdentifiers.SignUp))
    }
    
    func testColorParsing() {
        XCTAssertNotNil(oexColors.color(forIdentifier: OEXColors.ColorsIdentifiers.PrimaryBaseColor))
        XCTAssertNotNil(oexColors.color(forIdentifier: OEXColors.ColorsIdentifiers.PrimaryLightColor))
        XCTAssertNotNil(oexColors.color(forIdentifier: OEXColors.ColorsIdentifiers.PrimaryBaseColor, alpha: 0.5))
        XCTAssertNotNil(oexColors.color(forIdentifier: OEXColors.ColorsIdentifiers.PrimaryLightColor, alpha: 1.0))
        XCTAssertEqual(oexColors.color(forIdentifier: OEXColors.ColorsIdentifiers.PrimaryBaseColor), oexColors.color(forIdentifier: OEXColors.ColorsIdentifiers.PrimaryBaseColor, alpha: 1.0))
    }
    
    func testButtonColorParsing() {
        XCTAssertNotNil(oexColors.buttonColor(forIdentifier: OEXColors.ButtonsIdentifiers.SignUp))
        XCTAssertNotNil(oexColors.buttonColor(forIdentifier: OEXColors.ButtonsIdentifiers.Register))
        XCTAssertNotNil(oexColors.buttonColor(forIdentifier: OEXColors.ButtonsIdentifiers.SignUp, alpha: 0.5))
        XCTAssertNotNil(oexColors.buttonColor(forIdentifier: OEXColors.ButtonsIdentifiers.Register, alpha: 1.0))
        XCTAssertEqual(oexColors.buttonColor(forIdentifier: OEXColors.ButtonsIdentifiers.SignUp), oexColors.buttonColor(forIdentifier: OEXColors.ButtonsIdentifiers.SignUp, alpha: 1.0))
    }
}
