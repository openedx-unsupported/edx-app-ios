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
    
    func testCourseEnrollmentNoConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertEqual(config.courseEnrollmentConfig.type, EnrollmentType.None)
    }
    
    func testCourseEnrollmentEmptyConfig() {
        let config = OEXConfig(dictionary:["COURSE_ENROLLMENT":[:]])
        XCTAssertEqual(config.courseEnrollmentConfig.type, EnrollmentType.None)
    }
    
    func testCourseEnrollmentWebview() {
        let sampleSearchURL = "http://example.com/course-search"
        let sampleExploreURL = "http://example.com/explore-courses"
        let sampleInfoURLTemplate = "http://example.com/{path_id}"
        
        let configDictionary = [
            "COURSE_ENROLLMENT": [
                "TYPE": "webview",
                "WEBVIEW": [
                    "SEARCH_URL": sampleSearchURL,
                    "EXPLORE_SUBJECTS_URL": sampleExploreURL,
                    "DETAIL_TEMPLATE": sampleInfoURLTemplate,
                    "SEARCH_BAR_ENABLED": true
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.courseEnrollmentConfig.type, EnrollmentType.Webview)
        XCTAssertEqual(config.courseEnrollmentConfig.webview.searchURL!.absoluteString, sampleSearchURL)
        XCTAssertEqual(config.courseEnrollmentConfig.webview.detailTemplate!, sampleInfoURLTemplate)
        XCTAssertEqual(config.courseEnrollmentConfig.webview.exploreSubjectsURL!.absoluteString, sampleExploreURL)
        XCTAssertTrue(config.courseEnrollmentConfig.webview.searchbarEnabled)
    }
    
    func testProgramEnrollmentNoConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.programEnrollment.isProgramDiscoveryEnabled)
        XCTAssertEqual(config.programEnrollment.type, .None)
    }
    
    func testProgramEnrollmentEmptyConfig() {
        let config = OEXConfig(dictionary:["PROGRAM_ENROLLMENT":[:]])
        XCTAssertFalse(config.programEnrollment.isProgramDiscoveryEnabled)
        XCTAssertEqual(config.programEnrollment.type, .None)
    }
    
    func testInvalidProgramEnrollment() {
        let configDictionary = [
            "PROGRAM_ENROLLMENT": [
                "TYPE": "invalid"
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.programEnrollment.isProgramDiscoveryEnabled)
        XCTAssertEqual(config.programEnrollment.type, .None)
    }
    
    func testProgramEnrollmentWebview() {
        let sampleSearchURL = "http://example.com/program-search"
        let sampleDetailTemplate = "http://example.com/{path_id}"
        let configDictionary = [
            "PROGRAM_ENROLLMENT": [
                "TYPE": "webview",
                "WEBVIEW": [
                    "SEARCH_URL": sampleSearchURL,
                    "DETAIL_TEMPLATE": sampleDetailTemplate,
                    "SEARCH_BAR_ENABLED": true
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.programEnrollment.isProgramDiscoveryEnabled)
        XCTAssertEqual(config.programEnrollment.type, .Webview)
        XCTAssertEqual(config.programEnrollment.webview.detailTemplate!, sampleDetailTemplate)
        XCTAssertEqual(config.programEnrollment.webview.searchURL!.absoluteString, sampleSearchURL)
        XCTAssertTrue(config.programEnrollment.webview.searchbarEnabled)
    }

}
