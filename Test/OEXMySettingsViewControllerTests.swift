//
//  OEXMySettingsViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 11/12/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
import edX

class OEXMySettingsViewControllerTests: XCTestCase {
    func testLoadsView() {
        let controller = OEXMySettingsViewController()
        let view = controller.view
        XCTAssertNotNil(view)
    }
    
}
