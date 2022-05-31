//
//  DiscoveryConfigTests.swift
//  edX
//
//  Created by Akiva Leffert on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
@testable import edX

class DiscoveryConfigTests: XCTestCase {
    
    func testDiscoveryNoConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.discovery.isEnabled)
        XCTAssertEqual(config.discovery.type, .none)
    }
    
    func testDiscoveryEmptyConfig() {
        let config = OEXConfig(dictionary:["DISCOVERY":[:]])
        XCTAssertFalse(config.discovery.isEnabled)
        XCTAssertEqual(config.discovery.type, .none)
    }
    
    func testInvalidDiscovery() {
        let configDictionary = [
            "DISCOVERY": [
                "TYPE": "invalid"
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.discovery.isEnabled)
        XCTAssertEqual(config.discovery.type, .none)
    }
    
    func testDiscoveryWebview() {
        let sampleBaseURL = "http://example.com/course-search"
        let sampleInfoURLTemplate = "http://example.com/{path_id}"
        let sampleProgramInfoURLTemplate = "http://example.com/{path_id}"
        
        let configDictionary = [
            "DISCOVERY": [
                "TYPE": "webview",
                "WEBVIEW": [
                    "BASE_URL": sampleBaseURL,
                    "COURSE_DETAIL_TEMPLATE": sampleInfoURLTemplate,
                    "PROGRAM_DETAIL_TEMPLATE": sampleProgramInfoURLTemplate

                ]
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.discovery.type, .webview)
        XCTAssertEqual(config.discovery.webview.baseURL!.absoluteString, sampleBaseURL)
        XCTAssertEqual(config.discovery.webview.courseDetailTemplate!, sampleInfoURLTemplate)
        XCTAssertEqual(config.discovery.webview.programDetailTemplate!, sampleProgramInfoURLTemplate)
    }

}
