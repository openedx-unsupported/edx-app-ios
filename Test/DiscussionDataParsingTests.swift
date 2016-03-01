//
//  DiscussionDataParsingTests.swift
//  edX
//
//  Created by Saeed Bashir on 3/1/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
@testable import edX

class DiscussionDataParsingTests: XCTestCase {
   
    func testAnonymousUserPostParsed() {
        let testPost = JSON(resourceWithName : "DiscussionPosts")
        
        let anonymousPost = DiscussionThread(json: testPost)
        
        if let _ = anonymousPost?.author {
            XCTAssertFalse(false, "Failed to parse post by anonymous user")
        }
        else {
            XCTAssertTrue(true, "Successfully parsed post by anonymous user")
        }
        
    }
}