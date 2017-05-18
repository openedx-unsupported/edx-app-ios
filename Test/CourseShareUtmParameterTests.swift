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
 
    let courseSharingUtmParameters = ["facebook":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook", "twitter":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"]
    
    func testEmptyJsonForFacebook() {
        let courseShareUtmParams = CourseShareUtmParameter(dictionary:[:])
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNil(courseShareUtmParams?.facebook)
        XCTAssertNil(courseShareUtmParams?.twitter)
    }
    
    func testJsonForUtmParameter() {
        
        let courseShareUtmParams = CourseShareUtmParameter(dictionary:courseSharingUtmParameters)
        XCTAssertNotNil(courseShareUtmParams)
        XCTAssertNotNil(courseShareUtmParams?.twitter)
        XCTAssertNotNil(courseShareUtmParams?.facebook)
        XCTAssertEqual(courseShareUtmParams?.twitter, "utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter")
    }
    
    func testJsonForMissingTwitterUtmParameter() {
        let courseSharingUtmParameters = ["facebook":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=facebook"]
        let courseShareUtmParams = CourseShareUtmParameter(dictionary:courseSharingUtmParameters)
        XCTAssertNil(courseShareUtmParams?.twitter)
        XCTAssertNotNil(courseShareUtmParams?.facebook)
    }
    
    func testJsonForMissingFacebookUtmParameter() {
        let courseSharingUtmParameters = ["twitter":"utm_campaign=social-sharing&utm_medium=social-post&utm_source=twitter"]
        let courseShareUtmParams = CourseShareUtmParameter(dictionary:courseSharingUtmParameters)
        XCTAssertNil(courseShareUtmParams?.facebook)
        XCTAssertNotNil(courseShareUtmParams?.twitter)
    }
}
