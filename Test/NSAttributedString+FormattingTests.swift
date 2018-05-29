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
}
