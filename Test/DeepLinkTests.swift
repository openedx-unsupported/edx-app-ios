//
//  DeepLinkTests.swift
//  edXTests
//
//  Created by Salman on 05/10/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest
@testable import edX

class DeepLinkTests: XCTestCase {
    
    func testDeepLinkWithNoParameters() {
        let deepLink = DeepLink(dictionary: [:])
        XCTAssertNil(deepLink.courseId)
        XCTAssertNil(deepLink.screenName)
        XCTAssertEqual(deepLink.type, .none)
    }
    
    func testDeepLinkParameters() {
        let testCourseId = "course-id:test_course"
        let testScreenName = "course_dashboard"
        let parameters = [
                "course_id": testCourseId,
                "screen_name": testScreenName,
        ]
        let deepLink = DeepLink(dictionary: parameters)
        XCTAssertNotNil(deepLink.courseId)
        XCTAssertNotNil(deepLink.screenName)
        XCTAssertEqual(deepLink.courseId, testCourseId)
        XCTAssertEqual(deepLink.screenName, testScreenName)
        XCTAssertEqual(deepLink.type, .courseDashboard)
    }
    
    func testInvalidScreenName() {
        let testCourseId = "course-id:test_course"
        let testScreenName = "invalid_name"
        let parameters = [
            "course_id": testCourseId,
            "screen_name": testScreenName,
            ]
        let deepLink = DeepLink(dictionary: parameters)
        XCTAssertNotNil(deepLink.courseId)
        XCTAssertNotNil(deepLink.screenName)
        XCTAssertEqual(deepLink.courseId, testCourseId)
        XCTAssertEqual(deepLink.screenName, testScreenName)
        XCTAssertEqual(deepLink.type, .none)
    }
}
