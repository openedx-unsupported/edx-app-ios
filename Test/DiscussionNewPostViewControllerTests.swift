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
        let courseID = OEXCourse.freshCourse().course_id!
        let courseDataManager = MockCourseDataManager(querier: nil, topicsManager: nil)
        let environment = DiscussionNewPostViewController.Environment(courseDataManager: courseDataManager, networkManager: nil, router: nil)
        let topic = DiscussionTopic(id: nil, name: "Example", children: [], depth: 0)
        let controller = DiscussionNewPostViewController(environment: environment, courseID: courseID, ownerState : .Topic(topic))
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
}
