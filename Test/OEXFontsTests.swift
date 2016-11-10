//
//  OEXFontsTests.swift
//  edX
//
//  Created by José Antonio González on 11/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import edX
import XCTest


class OEXFontsTests: XCTestCase {
    
    var oexFonts : OEXFonts {
        return OEXFonts.sharedInstance
    }
    
    func testFontFileExistence() {
        let filePath : String? = NSBundle.mainBundle().pathForResource("fonts", ofType: "json")
        XCTAssertNotNil(filePath)
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(filePath ?? ""))
    }
    
    func testFontDataFactory() {
        let filePath : String? = NSBundle.mainBundle().pathForResource("incorrectfonts", ofType: "json")
        oexFonts.fallbackFonts()
        XCTAssertNil(filePath)
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.Regular, size: 12))
    }
    
    func testColorParsing() {
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.Regular, size: 12))
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.SemiBold, size: 12))
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.Bold, size: 12))
        XCTAssertNotNil(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.Light, size: 12))
        XCTAssertNotEqual(oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.Regular, size: 12), oexFonts.fontForIdentifier(OEXFonts.FontIdentifiers.SemiBold, size: 12))
    }
    
}
