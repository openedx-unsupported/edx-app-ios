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
        let link = ScreenLink(dictionary: [:])
        XCTAssertNil(link.courseId)
        XCTAssertNil(link.screenName)
        XCTAssertEqual(link.type, .none)
    }
    
    func testDeepLinkParameters() {
        let testCourseId = "course-id:test_course"
        let testScreenName = "course_dashboard"
        let parameters = [
                "course_id": testCourseId,
                "screen_name": testScreenName,
        ]
        let link = ScreenLink(dictionary: parameters)
        XCTAssertNotNil(link.courseId)
        XCTAssertNotNil(link.screenName)
        XCTAssertEqual(link.courseId, testCourseId)
        XCTAssertEqual(link.screenName, testScreenName)
        XCTAssertEqual(link.type, .courseDashboard)
    }
    
    func testInvalidScreenName() {
        let testCourseId = "course-id:test_course"
        let testScreenName = "invalid_name"
        let parameters = [
            "course_id": testCourseId,
            "screen_name": testScreenName,
            ]
        let link = ScreenLink(dictionary: parameters)
        XCTAssertNotNil(link.courseId)
        XCTAssertNotNil(link.screenName)
        XCTAssertEqual(link.courseId, testCourseId)
        XCTAssertEqual(link.screenName, testScreenName)
        XCTAssertEqual(link.type, .none)
    }
}
