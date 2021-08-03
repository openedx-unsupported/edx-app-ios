//
//  BrazeConfigTests.swift
//  edXTests
//
//  Created by Saeed Bashir on 4/14/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
@testable import edX

class BrazeConfigTests: XCTestCase {
    func testNoBrazeConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.brazeConfig.enabled)
    }

    func testEmptyBrazeConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.brazeConfig.enabled)
        XCTAssertFalse(config.brazeConfig.pushNotificationsEnabled)
    }

    func testBrazeConfig() {
        let configDictionary = [
            "BRAZE" : [
                "ENABLED": true,
                "PUSH_NOTIFICATIONS_ENABLED": true
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)

        XCTAssertTrue(config.brazeConfig.enabled)
        XCTAssertTrue(config.brazeConfig.pushNotificationsEnabled)
    }

    func testBrazeDisabledConfig() {
        let configDictionary = [
            "BRAZE" : [
                "ENABLED": false,
                "PUSH_NOTIFICATIONS_ENABLED": true
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)

        XCTAssertFalse(config.brazeConfig.enabled)
        XCTAssertFalse(config.brazeConfig.pushNotificationsEnabled)
    }
}
