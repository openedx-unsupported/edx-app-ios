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
    }
    
    func testDeepLinkParameters() {
        let testCourseId = "course-id:test_course"
        let testScreenName = "test_screen"
        let parameters = [
                "course_id": testCourseId,
                "screen_name": testScreenName,
        ]
        let deepLink = DeepLink(dictionary: parameters)
        XCTAssertNotNil(deepLink.courseId)
        XCTAssertNotNil(deepLink.screenName)
        XCTAssertEqual(deepLink.courseId, testCourseId)
        XCTAssertEqual(deepLink.screenName, testScreenName)
    }
}
