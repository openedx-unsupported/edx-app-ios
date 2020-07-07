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

    func testDiscoveryEnabledScreenshot() {
        let configDictionary = [
            "DISCOVERY": [
                "COURSE": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "BASE_URL": "www.example.com",
                    ]
                ],
                "PROGRAM": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "BASE_URL": "www.example.com",
                    ]
                ]
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        
        let mockEnv = TestRouterEnvironment(config: config, interface: nil)
        let controller = StartupViewController(environment: mockEnv)
        inScreenDisplayContext(controller) {
            assertSnapshotValidWithContent(controller)
        }
    }

    func testDiscoveryDisabledScreenshot() {
        let config = OEXConfig(dictionary: [:])

        let mockEnv = TestRouterEnvironment(config: config, interface: nil)
        let controller = StartupViewController(environment: mockEnv)
        inScreenDisplayContext(controller) {
            assertSnapshotValidWithContent(controller)
        }
    }

}
