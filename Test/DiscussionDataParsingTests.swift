//
//  DiscussionDataParsingTests.swift
//  edX
//
//  Created by Saeed Bashir on 3/1/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

import edXCore
@testable import edX

class DiscussionDataParsingTests: XCTestCase {
   
    func testAnonymousUserPostParsed() {

        let unparsed = JSON(resourceNamed: "DiscussionPosts")
        XCTAssertNil(unparsed["author"].string)
        
        let parsedThread = DiscussionThread(json:unparsed)
        XCTAssertNotNil(parsedThread)
        XCTAssertNil(parsedThread?.author)
    }
}