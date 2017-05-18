//
//  DiscussionNewPostViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 8/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class DiscussionNewPostViewControllerTests: SnapshotTestCase {

    func testContent() {
        let course = OEXCourse.freshCourse()
        let topics = DiscussionTopic.testTopics()
        let topicsManager = DiscussionDataManager(courseID : course.course_id!, topics : topics)
        let environment = TestRouterEnvironment()
        environment.mockCourseDataManager.topicsManager = topicsManager
        
        let controller = DiscussionNewPostViewController(environment: environment, courseID: course.course_id!, selectedTopic : topics[0])
        
        let expectations = expectation(description: "New post topics loaded")
        controller.t_topicsLoaded().listenOnce(self) {_ in
            expectations.fulfill()
        }
        waitForExpectations()
        
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
}
