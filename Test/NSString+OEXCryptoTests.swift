//
//  NSString+OEXCryptoTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class NSString_OEXCryptoTests: XCTestCase {

    func testExamples() {
        XCTAssertEqual("foo".oex_md5, "acbd18db4cc2f85cedef654fccc4a4d8")
        XCTAssertEqual("http://example.com".oex_md5, "a9b9f04336ce0181a08e774e01113b31")
        XCTAssertEqual("😊😊😊😊😊😊😊😊😊😊😊😊😊😊".oex_md5, "ef4d40d61aad3de9753f6b075c47580c")
    }
}
