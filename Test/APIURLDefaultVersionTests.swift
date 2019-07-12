//
//  APIURLDefaultVersionTests.swift
//  edXTests
//
//  Created by Salman on 12/07/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import XCTest
@testable import edX

class APIURLDefaultVersionTests: XCTestCase {

    func testNoAPIURLConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertEqual(config.apiUrlVersionConfig.blocks, APIURLDefaultVersion.blocks.rawValue)
    }
    
    func testEmptyAPIURLConfig() {
        let config = OEXConfig(dictionary:["API_URL_VERSION":[:]])
        XCTAssertEqual(config.apiUrlVersionConfig.blocks, APIURLDefaultVersion.blocks.rawValue)
    }
    
    func testAPIURLConfig() {
        let configDictionary = [
            "API_URL_VERSION" : [
                "BLOCKS": "v2",
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.apiUrlVersionConfig.blocks, "v2")
        XCTAssertNotEqual(config.apiUrlVersionConfig.blocks, APIURLDefaultVersion.blocks.rawValue)
    }
}
