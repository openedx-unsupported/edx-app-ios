//
//  OEXTextStyleTests.swift
//  edX
//
//  Created by Akiva Leffert on 9/16/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import XCTest

class OEXTextStyleTests: XCTestCase {
    
    // A text style sufficiently weird that none of its values will ever be the defaults
    var weirdStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .Bold, size: .XXLarge, color: UIColor.greenColor())
        style.lineBreakMode = NSLineBreakMode.ByClipping
        style.paragraphSpacing = 10
        style.paragraphSpacingBefore = 8
        style.alignment = .Right
        
        return style
    }

    func testCopy() {
        let style = weirdStyle
        let copy = style.mutableCopy() as! OEXTextStyle
        XCTAssertEqual(style.alignment, copy.alignment)
        XCTAssertEqual(style.letterSpacing, copy.letterSpacing)
        XCTAssertEqual(style.lineBreakMode, copy.lineBreakMode)
        XCTAssertEqual(style.weight, copy.weight)
        XCTAssertEqual(style.size, copy.size)
        XCTAssertEqual(style.color!, copy.color!)
        XCTAssertEqual(style.paragraphSpacing, copy.paragraphSpacing)
        XCTAssertEqual(style.paragraphSpacingBefore, copy.paragraphSpacingBefore)
    }
    
}
