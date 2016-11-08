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
    
    func testColorParsing() {
        XCTAssertNotNil(oexFonts.fontForIdentifier("regular"))
        XCTAssertNotNil(oexFonts.fontForIdentifier("semiBold"))
        XCTAssertNotNil(oexFonts.fontForIdentifier("bold"))
        XCTAssertNotNil(oexFonts.fontForIdentifier("light"))
        XCTAssertNotEqual(oexFonts.fontForIdentifier("regular"), oexFonts.fontForIdentifier("semiBold"))
    }
    
}
