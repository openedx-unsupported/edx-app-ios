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
        XCTAssertFalse(config.discovery.course.isEnabled)
        XCTAssertEqual(config.discovery.course.type, .none)
        XCTAssertFalse(config.discovery.program.isEnabled)
        XCTAssertEqual(config.discovery.program.type, .none)
    }
    
    func testDiscoveryEmptyConfig() {
        let config = OEXConfig(dictionary:["DISCOVERY":[:]])
        XCTAssertFalse(config.discovery.course.isEnabled)
        XCTAssertEqual(config.discovery.course.type, .none)
        XCTAssertFalse(config.discovery.program.isEnabled)
        XCTAssertEqual(config.discovery.program.type, .none)
    }
    
    func testCourseAndProgramDiscoveryEmptyConfig() {
        let config = OEXConfig(dictionary:["DISCOVERY":["COURSE":[:],"PROGRAM":[:]]])
        XCTAssertEqual(config.discovery.course.type, .none)
        XCTAssertEqual(config.discovery.program.type, .none)
    }
    
    func testInvalidCourseDiscovery() {
        let configDictionary = [
            "DISCOVERY": [
                "COURSE": [
                    "TYPE": "invalid"
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.discovery.course.isEnabled)
        XCTAssertEqual(config.discovery.course.type, .none)
    }
    
    func testCourseDiscoveryWebview() {
        let sampleBaseURL = "http://example.com/course-search"
        let sampleExploreURL = "http://example.com/explore-courses"
        let sampleInfoURLTemplate = "http://example.com/{path_id}"
        
        let configDictionary = [
            "DISCOVERY": [
                "COURSE": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "BASE_URL": sampleBaseURL,
                        "EXPLORE_SUBJECTS_URL": sampleExploreURL,
                        "DETAIL_TEMPLATE": sampleInfoURLTemplate,
                        "SEARCH_ENABLED": true
                    ]
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.discovery.course.type, .webview)
        XCTAssertEqual(config.discovery.course.webview.baseURL!.absoluteString, sampleBaseURL)
        XCTAssertEqual(config.discovery.course.webview.detailTemplate!, sampleInfoURLTemplate)
        XCTAssertEqual(config.discovery.course.webview.exploreSubjectsURL!.absoluteString, sampleExploreURL)
        XCTAssertTrue(config.discovery.course.webview.searchEnabled)
    }
    
    func testInvalidProgramDiscovery() {
        let configDictionary = [
            "DISCOVERY": [
                "PROGRAM": [
                    "TYPE": "invalid"
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.discovery.program.isEnabled)
        XCTAssertEqual(config.discovery.program.type, .none)
    }
    
    func testProgramDiscoveryWithOutCourseDiscovery() {
        
        let configDictionary = [
            "DISCOVERY": [
                "PROGRAM": [
                    "TYPE": "webview"
                ]
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.discovery.program.isEnabled)
    }
    
    func testCourseAndProgramDiscoveryWebView() {
        let sampleBaseURL = "http://example.com/program-search"
        let sampleDetailTemplate = "http://example.com/{path_id}"
        
        let sampleCourseBaseURL = "http://example.com/course-search"
        let sampleExploreURL = "http://example.com/explore-courses"
        let sampleInfoURLTemplate = "http://example.com/{path_id}"
        
        let configDictionary = [
            "DISCOVERY": [
                "PROGRAM": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "BASE_URL": sampleBaseURL,
                        "DETAIL_TEMPLATE": sampleDetailTemplate,
                        "SEARCH_ENABLED": true
                    ]
                ],
                "COURSE": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "BASE_URL": sampleCourseBaseURL,
                        "EXPLORE_SUBJECTS_URL": sampleExploreURL,
                        "DETAIL_TEMPLATE": sampleInfoURLTemplate,
                        "SEARCH_ENABLED": true
                    ]
                ]
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.discovery.program.isEnabled)
        XCTAssertEqual(config.discovery.program.type, .webview)
        XCTAssertEqual(config.discovery.program.webview.detailTemplate!, sampleDetailTemplate)
        XCTAssertEqual(config.discovery.program.webview.baseURL!.absoluteString, sampleBaseURL)
        XCTAssertTrue(config.discovery.program.webview.searchEnabled)
        XCTAssertEqual(config.discovery.course.type, .webview)
        XCTAssertEqual(config.discovery.course.webview.baseURL!.absoluteString, sampleCourseBaseURL)
        XCTAssertEqual(config.discovery.course.webview.detailTemplate!, sampleInfoURLTemplate)
        XCTAssertEqual(config.discovery.course.webview.exploreSubjectsURL!.absoluteString, sampleExploreURL)
        XCTAssertTrue(config.discovery.course.webview.searchEnabled)
    }

}
