//
//  UIEdgeInsets+GeometryTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

class UIEdgeInsets_GeometryTests: XCTestCase {

    func testPlus() {
        let left = UIEdgeInsets(top: -10, left: -20, bottom: -30, right: -40)
        let right = UIEdgeInsets(top: 5, left: 10, bottom: 15, right: 20)
        XCTAssertEqual(left + right, UIEdgeInsets(top: -5, left : -10, bottom : -15, right : -20))
    }

}
