//
//  AppUpgradeConfigTests.swift
//  edX
//
//  Created by Saeed Bashir on 8/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
@testable import edX

class AppUpgradeConfigTests: XCTestCase {
    let configDictionary = [
        "APP_UPDATE_URIS": [
            "www.example.com"
        ]
    ]
    
    func testEmptyConfig() {
        let config = OEXConfig(dictionary: [:])
        XCTAssertNil(config.appUpgradeConfig.iOSAppStoreURL())
    }
    
    func testConfig() {
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertNotNil(config.appUpgradeConfig.iOSAppStoreURL())
    }
}