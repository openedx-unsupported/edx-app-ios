//
//  DiscussionModelTests.swift
//  edX
//
//  Created by Saeed Bashir on 5/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX

class DiscussionModelTests: XCTestCase {
    func testParser() {
        
        let topicID = "test-id"
        let discussionModel = DiscussionModel(dictionary: ["topic_id":topicID])
        XCTAssertEqual(topicID, discussionModel.topicID)
    }
}
