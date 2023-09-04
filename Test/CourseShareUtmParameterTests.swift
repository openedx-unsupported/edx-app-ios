//
//  CourseShareUtmParameterTests.swift
//  edX
//
//  Created by Salman on 18/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

private let facebookUtmParamter = "utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook"
private let twitterUtmParameter = "utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"

class CourseShareUtmParameterTests: XCTestCase {
 
    func testNoCourseShareUtmParams() {
        let courseShareUtmParams = CourseShareUtmParameters(params:[:])
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNil(courseShareUtmParams?.facebook)
        XCTAssertNil(courseShareUtmParams?.twitter)
    }
    
    func testCourseShareUtmParamsParsing() {
        
        let utmParams = ["facebook":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook", "twitter":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"]
        let courseShareUtmParams = CourseShareUtmParameters(params:utmParams)
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNotNil(courseShareUtmParams?.twitter)
        XCTAssertNotNil(courseShareUtmParams?.facebook)
        XCTAssertEqual(courseShareUtmParams?.twitter, twitterUtmParameter)
        XCTAssertEqual(courseShareUtmParams?.facebook, facebookUtmParamter)
    }
    
    func testOnlyFacebookUtmParameters() {
        let utmParams = ["facebook":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook"]
        let courseShareUtmParams = CourseShareUtmParameters(params:utmParams)
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNil(courseShareUtmParams?.twitter)
        XCTAssertNotNil(courseShareUtmParams?.facebook)
        XCTAssertEqual(courseShareUtmParams?.facebook, facebookUtmParamter)
    }
    
    func testOnlyTwitterUtmParameters() {
        let utmParams = ["twitter":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"]
        let courseShareUtmParams = CourseShareUtmParameters(params:utmParams)
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNil(courseShareUtmParams?.facebook)
        XCTAssertNotNil(courseShareUtmParams?.twitter)
        XCTAssertEqual(courseShareUtmParams?.twitter, twitterUtmParameter)
    }
}
