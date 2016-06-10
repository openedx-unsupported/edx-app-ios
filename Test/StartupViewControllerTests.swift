//
//  StartupViewControllerTests.swift
//  edX
//
//  Created by Michael Katz on 6/9/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
@testable import edX

class StartupViewControllerTests: SnapshotTestCase {

    func testScreenshot() {
        let mockEnv = TestRouterEnvironment()
        let controller = StartupViewController(environment: mockEnv)
        inScreenDisplayContext(controller) {
            assertSnapshotValidWithContent(controller)
        }
    }
}
