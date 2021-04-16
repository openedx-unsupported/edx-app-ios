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
        XCTAssertNil(config.brazeConfig.apiKey)
        XCTAssertNil(config.brazeConfig.endPointKey)
    }

    func testEmptyBrazeConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.brazeConfig.enabled)
        XCTAssertNil(config.brazeConfig.apiKey)
        XCTAssertNil(config.brazeConfig.endPointKey)
    }

    func testBrazeConfig() {
        let apiKey = "a12dsf-fsadfd-112dsr34-ffdsg313"
        let endPointKey = "sdk.iad-0000.braze.com"

        let configDictionary = [
            "BRAZE" : [
                "ENABLED": true,
                "API_KEY": apiKey,
                "END_POINT_KEY": endPointKey,
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)

        XCTAssertTrue(config.brazeConfig.enabled)
        XCTAssertNotNil(config.brazeConfig.apiKey)
        XCTAssertNotNil(config.brazeConfig.endPointKey)

        XCTAssertEqual(config.brazeConfig.apiKey, apiKey)
        XCTAssertEqual(config.brazeConfig.endPointKey, endPointKey)
    }
}
