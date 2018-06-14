//
//  FindCoursesWebViewHelperTests.swift
//  edX
//
//  Created by Zeeshan Arif on 5/29/18.
//  Copyright © 2018 edX. All rights reserved.
//

@testable import edX

class FindCoursesWebViewHelperTests: XCTestCase {
    
    func testBuildQueryString() {
        let baseURL = "http://www.fakex.com/course"
        let params: [String: String] = ["search_query": "test".addingPercentEncodingForRFC3986]
        let expected = "http://www.fakex.com/course?search_query=test"
        let expectedURL = URL(string: expected)
        let output = FindCoursesWebViewHelper.buildQuery(baseURL: baseURL, params: params)
        
        XCTAssertEqual(expectedURL, output)
    }
    
    func testSearchQueryHasAlreadyQueryString() {
        let baseURL = "http://www.fakex.com/course?subject=test"
        let params: [String: String] = ["search_query": "test course".addingPercentEncodingForRFC3986]
        let expected = "http://www.fakex.com/course?subject=test&search_query=test%20course"
        let expectedURL = URL(string: expected)
        let output = FindCoursesWebViewHelper.buildQuery(baseURL: baseURL, params: params)
        
        XCTAssertEqual(expectedURL, output)
    }
    
}
