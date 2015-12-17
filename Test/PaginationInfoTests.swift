//
//  PaginationInfoTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX

class PaginationInfoTests: XCTestCase {
    
    func testParseSuccess() {
        let json = JSON([
            "count" : 25,
            "num_pages" : 3,
            "previous" : "http://example.com/previous",
            "next" : "http://example.com/next",
            ])
        let info = PaginationInfo(json: json)
        XCTAssertEqual(info!.pageCount, 3)
        XCTAssertEqual(info!.totalCount, 25)
        XCTAssertEqual(info!.next, NSURL(string: "http://example.com/next")!)
        XCTAssertEqual(info!.previous, NSURL(string: "http://example.com/previous")!)
    }
    
    func testParseFailure() {
        let json = JSON([
            "count" : 25,
            "previous" : "http://example.com/previous",
            "next" : "http://example.com/next",
            ])
        let info = PaginationInfo(json: json)
        XCTAssertNil(info)
    }

}
