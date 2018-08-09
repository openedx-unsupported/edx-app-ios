//
//  ProgramConfigTests.swift
//  edXTests
//
//  Created by Salman on 06/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest
@testable import edX

class ProgramConfigTests: XCTestCase {
    
    func testNoProgramConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertNil(config.programConfig.programURL)
        XCTAssertNil(config.programConfig.programDetailURLTemplate)
        XCTAssertFalse(config.programConfig.enabled)
    }
    
    func testEmptyProgramConfig() {
        let config = OEXConfig(dictionary:["PROGRAM":[:]])
        XCTAssertNil(config.programConfig.programURL)
        XCTAssertNil(config.programConfig.programDetailURLTemplate)
        XCTAssertFalse(config.programConfig.enabled)
    }
    
    func testProgramConfig() {
        let programUrl = "https://example-program.com"
        let programDetailUrlTemplate = "https://example-program-detail.com"
        let configDictionary = [
            "PROGRAM" : [
                "PROGRAM_URL": programUrl,
                "PROGRAM_DETAIL_URL_TEMPLATE": programDetailUrlTemplate,
                "ENABLED": true
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.programConfig.programURL?.absoluteString, programUrl)
        XCTAssertEqual(config.programConfig.programDetailURLTemplate, programDetailUrlTemplate)
        XCTAssertTrue(config.programConfig.enabled)
    }
}
