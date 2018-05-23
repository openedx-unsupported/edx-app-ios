//
//  NSAttributedString+FormattingTests.swift
//  edX
//
//  Created by Akiva Leffert on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX

class NSAttributedString_FormattingTests: XCTestCase {

    func testParameterization() {
        let f = { "Hello " + $0 }
        let style = OEXTextStyle(weight: .normal, size: .base, color: nil)
        let styled = style.apply(f: f)
        let name = "someone".applyStyle(style: style)
        let result = styled(name)
        XCTAssertEqual(result.string, "Hello someone")
    }
    
    func testDecodingHTMLEntities() {
        XCTAssertEqual("what is it that you&amp;#39;re really looking for when you conduct a user test?".decodingHTMLEntities, "what is it that you're really looking for when you conduct a user test?")
        XCTAssertEqual("what is it that you&#39;re really looking for when you conduct a user test?".decodingHTMLEntities, "what is it that you're really looking for when you conduct a user test?")
        XCTAssertEqual("This is awesome &hearts;".decodingHTMLEntities, "This is awesome ❤")
        XCTAssertEqual("This is awesome &amp;&hearts;".decodingHTMLEntities, "This is awesome ❤")
        XCTAssertEqual("we&#39;ve done with option one & two".decodingHTMLEntities, "we've done with option one & two")
        XCTAssertEqual("we&amp;#39;ve done with option one & two".decodingHTMLEntities, "we've done with option one & two")
    }
}
