//
//  UserAgentGeneratorTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/10/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
import WebKit
@testable import edX

class UserAgentGeneratorTests : XCTestCase {
    func testOverride() {
        let webview = WKWebView(frame: .zero, configuration: UserAgentGenerator.webViewConfiguration())
        let userAgent = webview.value(forKey: "userAgent") as? String
        XCTAssertNotNil(userAgent, "No WKWebView userAgent")
        XCTAssertTrue(userAgent?.contains(UserAgentGenerator.appVersionDescriptor) ?? false, "WKWebView userAgent incorrect")
    }
}
