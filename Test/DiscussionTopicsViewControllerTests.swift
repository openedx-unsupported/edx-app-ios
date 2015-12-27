//
//  DiscussionTopicsViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 7/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class DiscussionTopicsViewControllerTests: SnapshotTestCase {
    
    let course = OEXCourse.freshCourse()
    
    func recordWithTopics(topics : [DiscussionTopic]) {
        let topicsManager = DiscussionDataManager(courseID : course.course_id!, topics : topics)
        let environment = TestRouterEnvironment()
        environment.mockCourseDataManager.topicsManager = topicsManager
        let controller = DiscussionTopicsViewController(environment: environment, courseID: course.course_id!)
        let expectation = expectationWithDescription("Topics loaded")
        controller.t_topicsLoaded().listenOnce(self) {_ in
            expectation.fulfill()
        }
        waitForExpectations()
        
        inScreenNavigationContext(controller){
            assertSnapshotValidWithContent(controller.navigationController!)
        }

    }

    func testNoDiscussions() {
        recordWithTopics([])
    }
    
    func testContent() {
        let topics = DiscussionTopic.testTopics()
        recordWithTopics(topics)
    }
    
    func testSelectableTopic() {
        let topics = DiscussionTopic.testTopics()
        XCTAssert(!topics[0].isSelectable, "Topic is selectable even when the ID is nil")
        XCTAssert(topics[2].isSelectable, "Topic with valid ID not selectable")
    }

}
