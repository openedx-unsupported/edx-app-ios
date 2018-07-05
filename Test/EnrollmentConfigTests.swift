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
                "WEBVIEW" : [
                    "COURSE_SEARCH_URL" : sampleSearchURL,
                    "EXPLORE_SUBJECTS_URL": sampleExploreURL,
                    "COURSE_INFO_URL_TEMPLATE" : sampleInfoURLTemplate,
                    "SEARCH_BAR_ENABLED" : true
                ]
            ]
        ]
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertEqual(config.courseEnrollmentConfig.type, EnrollmentType.Webview)
        XCTAssertEqual(config.courseEnrollmentConfig.webviewConfig.searchURL!.absoluteString, sampleSearchURL)
        XCTAssertEqual(config.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate!, sampleInfoURLTemplate)
        XCTAssertEqual(config.courseEnrollmentConfig.webviewConfig.exploreSubjectsURL!.absoluteString, sampleExploreURL)
        XCTAssertTrue(config.courseEnrollmentConfig.webviewConfig.nativeSearchBarEnabled)
    }

}
