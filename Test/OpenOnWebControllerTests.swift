//
//  OpenOnWebControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import XCTest
import UIKit

class OpenOnWebControllerTests: XCTestCase {
    func testButtonHasAction() {
        let displayController = UIViewController()
        let controller = OpenOnWebController(inViewController : displayController)
        XCTAssertFalse(controller.barButtonItem.enabled)
        
        controller.URL = NSURL(string: "http://example.com")
        XCTAssertTrue(controller.barButtonItem.enabled)
        
        XCTAssertTrue(controller.barButtonItem.hasTapAction)
    }
}
