//
//  MicrosoftConfigTests.swift
//  edXTests
//
//  Created by Salman on 30/10/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import XCTest

@testable import edX

let microsoftAppID = "3000c01b-0c11-0111-1111-e0ae10101de0"

class MicrosoftConfigTests: XCTestCase {

    func testNoMicrosoftConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.microsoftConfig.enabled)
        XCTAssertNil(config.microsoftConfig.appID)
    }
    
    func testEmptyMicrosoftConfig() {
        let config = OEXConfig(dictionary:["MICROSOFT":[:]])
        XCTAssertFalse(config.microsoftConfig.enabled)
        XCTAssertNil(config.microsoftConfig.appID)
    }
    
    func testMicrosoftConfig() {
        let configDictionary = [
            "MICROSOFT" : [
                "MICROSOFT_LOGIN_ENABLED": true,
                "MICROSOFT_APP_ID" : microsoftAppID
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.microsoftConfig.enabled)
        XCTAssertEqual(config.microsoftConfig.appID, microsoftAppID)
    }
}
