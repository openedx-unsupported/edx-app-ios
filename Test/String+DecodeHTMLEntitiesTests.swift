//
//  String+DecodeHTMLEntitiesTests.swift
//  edXTests
//
//  Created by Salman on 29/05/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest

class String_DecodeHTMLEntitiesTests: XCTestCase {
    
    func testDecodingHTMLEntities() {
        XCTAssertEqual("what is it that you&amp;#39;re really looking for when you conduct a user test?".decodingHTMLEntities, "what is it that you're really looking for when you conduct a user test?")
        XCTAssertEqual("what is it that you&#39;re really looking for when you conduct a user test?".decodingHTMLEntities, "what is it that you're really looking for when you conduct a user test?")
        XCTAssertEqual("This is awesome &hearts;".decodingHTMLEntities, "This is awesome ♥")
        XCTAssertEqual("This is awesome &amp;&hearts;".decodingHTMLEntities, "This is awesome &♥")
        XCTAssertEqual("we&#39;ve done with option one & two".decodingHTMLEntities, "we've done with option one & two")
        XCTAssertEqual("we&amp;#39;ve done with option one & two".decodingHTMLEntities, "we've done with option one & two")
        XCTAssertEqual("we&amp;#39;ve done with option &one; & &two;".decodingHTMLEntities, "we've done with option &one; & &two;")
        XCTAssertEqual("&#x3C;p&#x3E;&#x22;caf&#xE9;&#x22;&#x3C;/p&#x3E;".decodingHTMLEntities, "<p>\"café\"</p>")
        XCTAssertEqual("&lt;script&gt;alert(&quot;abc&quot;)&lt;/script&gt;".decodingHTMLEntities, "<script>alert(\"abc\")</script>")
        XCTAssertEqual("&#127482;&#127480; is superpower.".decodingHTMLEntities, "🇺🇸 is superpower.")
    }
}
