//
//  CourseShareUtmParameterTests.swift
//  edX
//
//  Created by Salman on 18/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class CourseShareUtmParameterTests: XCTestCase {
 
    let facebookUtmParamter = "utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook"
    let twitterUtmParameter = "utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"
    let courseSharingUtmParameters = ["facebook":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook", "twitter":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"]
    
    func testNoCourseShareUtmParams() {
        let courseShareUtmParams = CourseShareUtmParameters(Params:[:])
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNil(courseShareUtmParams?.facebook)
        XCTAssertNil(courseShareUtmParams?.twitter)
    }
    
    func testCourseShareUtmParamsParsing() {
        
        let courseShareUtmParams = CourseShareUtmParameters(Params:courseSharingUtmParameters)
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNotNil(courseShareUtmParams?.twitter)
        XCTAssertNotNil(courseShareUtmParams?.facebook)
        XCTAssertEqual(courseShareUtmParams?.twitter, twitterUtmParameter)
        XCTAssertEqual(courseShareUtmParams?.facebook, facebookUtmParamter)
    }
    
    func testOnlyTwitterUtmParameters() {
        let courseSharingUtmParameters = ["facebook":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook"]
        let courseShareUtmParams = CourseShareUtmParameters(Params:courseSharingUtmParameters)
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNil(courseShareUtmParams?.twitter)
        XCTAssertNotNil(courseShareUtmParams?.facebook)
    }
    
    func testOnlyFacebookUtmParameters() {
        let courseSharingUtmParameters = ["twitter":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"]
        let courseShareUtmParams = CourseShareUtmParameters(Params:courseSharingUtmParameters)
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNil(courseShareUtmParams?.facebook)
        XCTAssertNotNil(courseShareUtmParams?.twitter)
    }
}
