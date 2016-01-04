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
        let thread = DiscussionThread(
            threadID: "123",
            type: .Discussion,
            courseId: "some-course",
            topicId: "abc",
            groupId: nil,
            groupName: nil,
            title: "Some Post",
            rawBody: nil,
            renderedBody: "Lorem ipsum dolor sit amet",
            author: "Test Person",
            authorLabel: "Staff",
            commentCount: 0,
            commentListUrl: nil,
            hasEndorsed: false,
            pinned: false,
            closed: false,
            following: false,
            flagged: false,
            abuseFlagged: false,
            voted: true,
            voteCount: 4,
            createdAt: NSDate(timeIntervalSince1970: 12345),
            updatedAt: nil,
            editableFields: nil,
            read: true,
            unreadCommentCount: 0,
            responseCount: 0)
        let controller = DiscussionNewCommentViewController(environment: environment, courseID: courseID, context : .Thread(thread))
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testContentResponse() {
        let courseID = OEXCourse.freshCourse().course_id!
        let environment = TestRouterEnvironment()
        let comment = DiscussionComment(
            commentID: "123",
            parentID: nil,
            threadID: "345",
            rawBody: nil,
            renderedBody: "Lorem ipsum dolor sit amet",
            author: "Test Person",
            authorLabel: nil,
            voted: true,
            voteCount: 10,
            createdAt: NSDate(timeIntervalSince1970: 12345),
            updatedAt: nil,
            endorsed: true,
            endorsedBy: nil,
            endorsedByLabel: nil,
            endorsedAt: nil,
            flagged: false,
            abuseFlagged: false,
            editableFields: nil,
            childCount: 0)
       
        let controller = DiscussionNewCommentViewController(environment: environment, courseID: courseID, context: .Comment(comment))
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
}
