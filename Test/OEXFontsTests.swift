//
//  OEXFontsTests.swift
//  edX
//
//  Created by José Antonio González on 11/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import edX
import XCTest

enum FontIdentifiers: Int {
    case Regular = 1, SemiBold, Bold, Light
}

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
        XCTAssertNotNil(oexFonts.fontForIdentifier(FontIdentifiers.Regular.rawValue))
    }
    
    func testColorParsing() {
        XCTAssertNotNil(oexFonts.fontForIdentifier(FontIdentifiers.Regular.rawValue))
        XCTAssertNotNil(oexFonts.fontForIdentifier(FontIdentifiers.SemiBold.rawValue))
        XCTAssertNotNil(oexFonts.fontForIdentifier(FontIdentifiers.Bold.rawValue))
        XCTAssertNotNil(oexFonts.fontForIdentifier(FontIdentifiers.Light.rawValue))
        XCTAssertNotEqual(oexFonts.fontForIdentifier(FontIdentifiers.Regular.rawValue), oexFonts.fontForIdentifier(FontIdentifiers.SemiBold.rawValue))
    }
    
}
