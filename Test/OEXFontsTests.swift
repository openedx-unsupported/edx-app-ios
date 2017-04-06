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
        let filePath : String? = Bundle.main.path(forResource: "fonts", ofType: "json")
        XCTAssertNotNil(filePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath ?? ""))
    }
    
    func testFontDataFactory() {
        oexFonts.fallbackFonts()
        XCTAssertNotNil(oexFonts.font(forIdentifier: OEXFonts.FontIdentifiers.Regular, size: 12))
    }
    
    func testFontParsing() {
        XCTAssertNotNil(oexFonts.font(forIdentifier: OEXFonts.FontIdentifiers.Regular, size: 12))
        XCTAssertNotNil(oexFonts.font(forIdentifier: OEXFonts.FontIdentifiers.SemiBold, size: 12))
        XCTAssertNotNil(oexFonts.font(forIdentifier: OEXFonts.FontIdentifiers.Bold, size: 12))
        XCTAssertNotNil(oexFonts.font(forIdentifier: OEXFonts.FontIdentifiers.Light, size: 12))
        XCTAssertNotEqual(oexFonts.font(forIdentifier: OEXFonts.FontIdentifiers.Regular, size: 12), oexFonts.font(forIdentifier: OEXFonts.FontIdentifiers.SemiBold, size: 12))
    }
    
}
