//
//  DiscussionTopicTests.swift
//  edX
//
//  Created by Akiva Leffert on 7/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class DiscussionTopicTests: XCTestCase {

    func testLinearization() {
        let topics = DiscussionTopic.testTopics()
        let expectedIDs = DiscussionTopic.testTopicIDsLinearized()
        let foundIDs = DiscussionTopic.linearizeTopics(topics: topics).map {
            return $0.id
        }
        
        let match = zip(expectedIDs, foundIDs).reduce(true) { (current, item) in
            current && (item.0 == item.1)
        }
        
        XCTAssertTrue(match)
    }
}
