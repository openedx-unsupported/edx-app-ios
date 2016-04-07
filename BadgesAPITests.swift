//
//  BadgesAPITests.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

import edXCore

class BadgesAPITests : XCTestCase {

    private var sampleBadgeJSON : JSON {
        return [
            "username" : "foo",
            "evidence": "http://example.com/evidence",
            "image_url": "http://example.com/image.jpg",
            "awarded_on": OEXDateFormatting.serverStringWithDate(NSDate()),
            "spec": [
                "description" : "Some cool badge!",
                "slug": "someslug",
                "issuing_component": "somecomponent",
                "name": "some name",
                "image_url": "http://example.com/image.jpg",
                "course_id": "some+course+id",
            ]
        ]
    }

    func testRequest() {
        let request = BadgesAPI.requestBadgesForUser("someuser")
        XCTAssertTrue(request.path.containsString("someuser"))
        XCTAssertEqual(request.method, HTTPMethod.GET)
    }

    func testParsingBadInput() {
        let request = BadgesAPI.requestBadgesForUser("someuser")
        switch request.deserializer {
        case let .JSONResponse(deserializer):
            let response = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)!
            let result = deserializer(response, JSON("not a list"))
            AssertFailure(result)
            default:
                XCTFail()
        }
    }

    func testParsingSuccess() {
        let request = BadgesAPI.requestBadgesForUser("someuser")
        switch request.deserializer {
        case let .JSONResponse(deserializer):
            let response = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)!
            let result = deserializer(response, JSON([sampleBadgeJSON, sampleBadgeJSON]))
            AssertSuccess(result)
            XCTAssertEqual(result.value!.count, 2)
        default:
            XCTFail()
        }
    }

    func testParsingSkipsFailure() {
        let request = BadgesAPI.requestBadgesForUser("someuser")
        switch request.deserializer {
        case let .JSONResponse(deserializer):
            let response = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)!
            let result = deserializer(response, JSON([sampleBadgeJSON, ["foo":"bar"]]))
            AssertSuccess(result)
            XCTAssertEqual(result.value!.count, 1)
        default:
            XCTFail()
        }
    }
}