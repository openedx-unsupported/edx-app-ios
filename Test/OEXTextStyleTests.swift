//
//  OEXTextStyleTests.swift
//  edX
//
//  Created by Akiva Leffert on 9/16/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import XCTest

func verifyEqualityWithNewValue<A>(_ style : OEXTextStyle, _ copy : OEXMutableTextStyle, _ testValue : A, _ setter : (OEXMutableTextStyle, A) -> Void, _ getter : (OEXTextStyle) -> A) {
    XCTAssertEqual(style, copy)
    setter(copy, testValue)
    XCTAssertNotEqual(style, copy)
    setter(copy, getter(style))
}

class OEXTextStyleTests: XCTestCase {
    
    // A text style sufficiently weird that none of its values will ever be the defaults
    var weirdStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .bold, size: .xxLarge, color: UIColor.green)
        style.lineBreakMode = NSLineBreakMode.byClipping
        style.paragraphSpacing = 10
        style.paragraphSpacingBefore = 8
        style.alignment = .right
        style.letterSpacing = .xxLoose
        
        return style
    }
    
    func testEquality() {
        let style = weirdStyle
        let copy = style.mutableCopy() as! OEXMutableTextStyle
        
        verifyEqualityWithNewValue(style, copy, .light, {$0.weight = $1}, {$0.weight})
        verifyEqualityWithNewValue(style, copy, .xxSmall, {$0.size = $1}, {$0.size})
        verifyEqualityWithNewValue(style, copy, UIColor.orange as UIColor?, {$0.color = $1}, {$0.color})
        verifyEqualityWithNewValue(style, copy, .left, {$0.alignment = $1}, {$0.alignment})
        verifyEqualityWithNewValue(style, copy, 20, {$0.paragraphSpacing = $1}, {$0.paragraphSpacing})
        verifyEqualityWithNewValue(style, copy, 20, {$0.paragraphSpacingBefore = $1}, {$0.paragraphSpacingBefore})
        verifyEqualityWithNewValue(style, copy, .byCharWrapping, {$0.lineBreakMode = $1}, {$0.lineBreakMode})
        verifyEqualityWithNewValue(style, copy, .xxTight, {$0.letterSpacing = $1}, {$0.letterSpacing})
    }
    
    func testNilInequality() {
        XCTAssertFalse((weirdStyle as OEXTextStyle?) == (nil as OEXTextStyle?))
    }

    func testCopy() {
        let style = weirdStyle
        let copy = style.copy() as! OEXTextStyle
        XCTAssertEqual(style, copy)
    }
    
    func testMutableCopy() {
        let style = weirdStyle
        let copy = style.mutableCopy() as! OEXMutableTextStyle
        XCTAssertEqual(style, copy)
    }
    
    func testMutableCopyConstructor() {
        let style = weirdStyle
        let copy = OEXMutableTextStyle(textStyle: style)
        XCTAssertEqual(style, copy)
    }
    
    func testAttributedString() {
        let sampleResponse = "This is a sample response."
        let style = weirdStyle
        
        XCTAssertEqual(style.attributedString(withText: sampleResponse).string, sampleResponse)
    }
    
    func testMarkdownString() {
        let htmlString = "<p>This is a response with a <a href=\"http://www.google.com/\">link</a></p>"
        let expectedString = "This is a response with a link"
        let style = weirdStyle
        
        XCTAssertEqual(style.markdownString(withText: htmlString).string, expectedString)
    }
    
}
