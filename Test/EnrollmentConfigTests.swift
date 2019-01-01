//
//  OEXConfigTests.swift
//  edX
//
//  Created by Akiva Leffert on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
@testable import edX

class EnrollmentConfigTests : XCTestCase {
    
    func testEnrollmentNoConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.enrollment.course.isEnabled)
        XCTAssertEqual(config.enrollment.course.type, .None)
        XCTAssertFalse(config.enrollment.program.isEnabled)
        XCTAssertEqual(config.enrollment.program.type, .None)
    }
    
    func testEnrollmentEmptyConfig() {
        let config = OEXConfig(dictionary:["ENROLLMENT":[:]])
        XCTAssertFalse(config.enrollment.course.isEnabled)
        XCTAssertEqual(config.enrollment.course.type, .None)
        XCTAssertFalse(config.enrollment.program.isEnabled)
        XCTAssertEqual(config.enrollment.program.type, .None)
    }
    
    func testCourseAndProgramEnrollmentEmptyConfig() {
        let config = OEXConfig(dictionary:["ENROLLMENT":["COURSE":[:],"PROGRAM":[:]]])
        XCTAssertEqual(config.enrollment.course.type, .None)
        XCTAssertEqual(config.enrollment.program.type, .None)
    }
    
    func testInvalidCourseEnrollment() {
        let configDictionary = [
            "ENROLLMENT": [
                "COURSE": [
                    "TYPE": "invalid"
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.enrollment.course.isEnabled)
        XCTAssertEqual(config.enrollment.course.type, .None)
    }
    
    func testCourseEnrollmentWebview() {
        let sampleSearchURL = "http://example.com/course-search"
        let sampleExploreURL = "http://example.com/explore-courses"
        let sampleInfoURLTemplate = "http://example.com/{path_id}"
        
        let configDictionary = [
            "ENROLLMENT": [
                "COURSE": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "SEARCH_URL": sampleSearchURL,
                        "EXPLORE_SUBJECTS_URL": sampleExploreURL,
                        "DETAIL_TEMPLATE": sampleInfoURLTemplate,
                        "SEARCH_BAR_ENABLED": true
                    ]
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.enrollment.course.type, .Webview)
        XCTAssertEqual(config.enrollment.course.webview.searchURL!.absoluteString, sampleSearchURL)
        XCTAssertEqual(config.enrollment.course.webview.detailTemplate!, sampleInfoURLTemplate)
        XCTAssertEqual(config.enrollment.course.webview.exploreSubjectsURL!.absoluteString, sampleExploreURL)
        XCTAssertTrue(config.enrollment.course.webview.searchbarEnabled)
    }
    
    func testInvalidProgramEnrollment() {
        let configDictionary = [
            "ENROLLMENT": [
                "PROGRAM": [
                    "TYPE": "invalid"
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.enrollment.program.isEnabled)
        XCTAssertEqual(config.enrollment.program.type, .None)
    }
    
    func testProgramEnrollmentWithOutCourseEnrollment() {
        
        let configDictionary = [
            "ENROLLMENT": [
                "PROGRAM": [
                    "TYPE": "webview"
                ]
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.enrollment.program.isEnabled)
    }
    
    func testCourseAndProgramEnrollmentWebView() {
        let sampleSearchURL = "http://example.com/program-search"
        let sampleDetailTemplate = "http://example.com/{path_id}"
        
        let sampleCourseSearchURL = "http://example.com/course-search"
        let sampleExploreURL = "http://example.com/explore-courses"
        let sampleInfoURLTemplate = "http://example.com/{path_id}"
        
        let configDictionary = [
            "ENROLLMENT": [
                "PROGRAM": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "SEARCH_URL": sampleSearchURL,
                        "DETAIL_TEMPLATE": sampleDetailTemplate,
                        "SEARCH_BAR_ENABLED": true
                    ]
                ],
                "COURSE": [
                    "TYPE": "webview",
                    "WEBVIEW": [
                        "SEARCH_URL": sampleCourseSearchURL,
                        "EXPLORE_SUBJECTS_URL": sampleExploreURL,
                        "DETAIL_TEMPLATE": sampleInfoURLTemplate,
                        "SEARCH_BAR_ENABLED": true
                    ]
                ]
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.enrollment.program.isEnabled)
        XCTAssertEqual(config.enrollment.program.type, .Webview)
        XCTAssertEqual(config.enrollment.program.webview.detailTemplate!, sampleDetailTemplate)
        XCTAssertEqual(config.enrollment.program.webview.searchURL!.absoluteString, sampleSearchURL)
        XCTAssertTrue(config.enrollment.program.webview.searchbarEnabled)
        XCTAssertEqual(config.enrollment.course.type, .Webview)
        XCTAssertEqual(config.enrollment.course.webview.searchURL!.absoluteString, sampleCourseSearchURL)
        XCTAssertEqual(config.enrollment.course.webview.detailTemplate!, sampleInfoURLTemplate)
        XCTAssertEqual(config.enrollment.course.webview.exploreSubjectsURL!.absoluteString, sampleExploreURL)
        XCTAssertTrue(config.enrollment.course.webview.searchbarEnabled)
    }

}
