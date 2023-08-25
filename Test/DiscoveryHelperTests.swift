//
//  DiscoveryHelperTests.swift
//  edXTests
//
//  Created by Salman on 06/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest
@testable import edX

private let sampleInvalidProgramDetailURL = "//course_info?path_id=usmx-corporate-finance"
private let sampleEnrolledProgramDetailURL = "edxapp://enrolled_program_info?path_id=programs/a3951294-926b-4247-8c3c-51c1e4347a15/details_fragment"
private let sampleEnrolledCourseDetailURL = "edxapp://enrolled_course_info?course_id=course-v1:USMx+BUMM612+2T2018"
private let sampleProgramCourseURL = "edxapp://course_info?path_id=usmx-corporate-finance"
private let sampleCourseEnrollmentURL = "edxapp://enroll?course_id=course-v1:USMx+BUMM610+3T2018&email_opt_in=true"
private let sampleProgramURL = "https://example.com/dashboard/programs_fragment/?mobile_only=true"
private let sampleInvalidProgramURLTemplate = "https://example.com/dashboard/mobile_only=true"
private let sampleProgramURLTemplate = "https://example.com/dashboard/{path_id}?mobile_only=true"
private let sampleProgramDetailURL = "https://example.com/dashboard/programs/a3951294-926b-4247-8c3c-51c1e4347a15/details_fragment?mobile_only=true"

private extension OEXConfig {
    
    convenience init(programURL: String = "", programDetailURLTemplate:String = "", enabled: Bool = false) {
        self.init(dictionary: [
            "PROGRAM" : [
                "PROGRAM_URL": programURL,
                "PROGRAM_DETAIL_URL_TEMPLATE": programDetailURLTemplate,
                "ENABLED": enabled
                ] as [String : Any]
            ]
        )
    }
}

class DiscoveryHelperTests: XCTestCase {
    
    func testAppURL() {
        var url = DiscoveryHelper.urlAction(from: URL(string: sampleEnrolledProgramDetailURL)!)
        XCTAssertEqual(url, WebviewActions.enrolledProgramDetail)
        
        url = DiscoveryHelper.urlAction(from: URL(string: sampleEnrolledCourseDetailURL)!)
        XCTAssertEqual(url, WebviewActions.enrolledCourseDetail)
        
        url = DiscoveryHelper.urlAction(from: URL(string: sampleProgramCourseURL)!)
        XCTAssertEqual(url, WebviewActions.courseDetail)
        
        url = DiscoveryHelper.urlAction(from: URL(string: sampleCourseEnrollmentURL)!)
        XCTAssertEqual(url, WebviewActions.courseEnrollment)
    }
    
    func testInvalidAppURL() {
        let url = DiscoveryHelper.urlAction(from: URL(string: sampleInvalidProgramDetailURL)!)
        XCTAssertNil(url)
    }
    
    func testDetailPathID() {
        let pathID = DiscoveryHelper.detailPathID(from: URL(string: sampleProgramCourseURL)!)
        XCTAssertEqual(pathID, "usmx-corporate-finance")
    }
    
    func testInvalidDetailPathID() {
        var url = DiscoveryHelper.detailPathID(from: URL(string: sampleInvalidProgramDetailURL)!)
        XCTAssertNil(url)
        
         url = DiscoveryHelper.detailPathID(from: URL(string: sampleEnrolledProgramDetailURL)!)
        XCTAssertNil(url)
    }
    
    func testParseURL() {
        let urlData = DiscoveryHelper.parse(url: URL(string: sampleCourseEnrollmentURL)!)
        XCTAssertEqual(urlData?.courseId, "course-v1:USMx+BUMM610+3T2018")
        XCTAssertTrue((urlData?.emailOptIn)!)        
    }
    
    func testParseURLFail() {
        let urlData = DiscoveryHelper.parse(url: URL(string: sampleInvalidProgramDetailURL)!)
        XCTAssertNil(urlData)
    }
    
    func testProgramURL(){
        var config = OEXConfig(programURL: sampleProgramURL, programDetailURLTemplate: sampleProgramURLTemplate, enabled: true)

        var url = DiscoveryHelper.programDetailURL(from: URL(string: sampleEnrolledProgramDetailURL)!, config: config)
        XCTAssertEqual(url?.absoluteString, sampleProgramDetailURL)

        url = DiscoveryHelper.programDetailURL(from: URL(string: sampleInvalidProgramURLTemplate)!, config: config)
        XCTAssertNil(url)
        
        config = OEXConfig(programURL:sampleProgramURLTemplate, enabled: true)
        url = DiscoveryHelper.programDetailURL(from: URL(string: sampleEnrolledProgramDetailURL)!, config: config)
        XCTAssertNil(url)
    }
}
