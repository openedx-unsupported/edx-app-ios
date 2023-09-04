//
//  DiscussionNewCommentViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 8/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

@testable import edX
import UIKit
import XCTest

class DiscussionNewCommentViewControllerTests: SnapshotTestCase {
    
    func testContentPost() {
        let courseID = OEXCourse.freshCourse().course_id!
        let environment = TestRouterEnvironment()
        let thread = DiscussionTestsDataFactory.thread
        let controller = DiscussionNewCommentViewController(environment: environment, courseID: courseID, thread:thread, context : .Thread(thread))
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testContentResponse() {
        let courseID = OEXCourse.freshCourse().course_id!
        let environment = TestRouterEnvironment()
        let comment = DiscussionTestsDataFactory.endorsedComment
       
        let controller = DiscussionNewCommentViewController(environment: environment, courseID: courseID,thread:nil, context: .Comment(comment))
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
}
