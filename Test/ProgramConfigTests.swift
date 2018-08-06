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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testProgramConfig() {
        let programUrl = "https://example-program.com"
        let programDetailUrlTemplate = "https://example-program-detail.com"
        let configDictionary = [
            "PROGRAM" : [
                "PROGRAM_URL": programUrl,
                "PROGRAM_DETAIL_URL_TEMPLATE": programDetailUrlTemplate,
                "PROGRAM_ENABLED": true
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.programConfig.programURL?.absoluteString, programUrl)
        XCTAssertEqual(config.programConfig.programDetailURL, programDetailUrlTemplate)
        XCTAssertTrue(config.programConfig.programEnabled)
    }
}
