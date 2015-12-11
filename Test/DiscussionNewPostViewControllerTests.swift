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
        let environment = TestRouterEnvironment()
        let topic = DiscussionTopic(id: nil, name: "Example", children: [], depth: 0)
        let controller = DiscussionNewPostViewController(environment: environment, courseID: courseID, selectedTopic : topic)
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
}
