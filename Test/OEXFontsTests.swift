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
        let fallbackFonts = ["regular":"OpenSans",
                             "semiBold":"OpenSans-Semibold",
                             "bold":"OpenSans-Bold",
                             "light":"OpenSans-Light",
                             "irregular":"Zapfino"]
        
        XCTAssertNil(filePath)
        XCTAssertEqual(oexFonts.fallbackFonts(), fallbackFonts)
        XCTAssertNotNil(oexFonts.fontForIdentifier("regular"))
    }
    
    func testColorParsing() {
        XCTAssertNotNil(oexFonts.fontForIdentifier("regular"))
        XCTAssertNotNil(oexFonts.fontForIdentifier("semiBold"))
        XCTAssertNotNil(oexFonts.fontForIdentifier("bold"))
        XCTAssertNotNil(oexFonts.fontForIdentifier("light"))
        XCTAssertNotEqual(oexFonts.fontForIdentifier("regular"), oexFonts.fontForIdentifier("semiBold"))
    }
    
}
