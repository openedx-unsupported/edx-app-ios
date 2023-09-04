//
//  DiscussionBlockViewControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 5/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX

class DiscussionBlockViewControllerTests : XCTestCase {
    
    func testPostViewControllerInitialization() {
        
        let discussionModel = DiscussionModel(dictionary: ["topic_id": "test-id"])
        let environment = TestRouterEnvironment()
        
        let discussionBlockController = DiscussionBlockViewController(blockID: "discussion", courseID: "some-course", topicID: discussionModel.topicID, environment: environment)
        discussionBlockController.view.setNeedsDisplay()
        
        XCTAssertNotNil(discussionBlockController.children[0])
    }
}
