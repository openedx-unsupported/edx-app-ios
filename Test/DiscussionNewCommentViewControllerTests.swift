//
//  DiscussionNewCommentViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 8/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class DiscussionNewCommentViewControllerTests: SnapshotTestCase {
    
    func testContentPost() {
        let courseID = OEXCourse.freshCourse().course_id!
        let courseDataManager = MockCourseDataManager(querier: nil, topicsManager: nil)
        let environment = DiscussionNewCommentViewController.Environment(courseDataManager : courseDataManager, networkManager : nil, router: nil)
        let post = DiscussionPostItem(
            title: "Some Post",
            body: "Lorem ipsum dolor sit amet",
            author: "Test Person",
            authorLabel: AuthorLabelType.Staff,
            createdAt: NSDate(timeIntervalSince1970: 12345),
            count: 3,
            threadID: "123",
            following: false,
            flagged: false,
            pinned: false,
            voted: true,
            voteCount: 4,
            type : .Discussion,
            read : true,
            unreadCommentCount: 0,
            closed : false,
            groupName : "Some Group"
        )
        let controller = DiscussionNewCommentViewController(environment: environment, courseID: courseID, item : DiscussionItem.Post(post))
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testContentResponse() {
        let courseID = OEXCourse.freshCourse().course_id!
        let courseDataManager = MockCourseDataManager(querier: nil, topicsManager: nil)
        let environment = DiscussionNewCommentViewController.Environment(courseDataManager : courseDataManager, networkManager : nil, router: nil)
        let response = DiscussionResponseItem(
            body: "Lorem ipsum dolor sit amet",
            author: "Test Person",
            createdAt: NSDate(timeIntervalSince1970: 12345),
            voteCount: 10,
            responseID: "123",
            threadID: "345",
            flagged: false,
            voted: true,
            children: [],
            commentCount: 0
        )
        let controller = DiscussionNewCommentViewController(environment: environment, courseID: courseID, item : DiscussionItem.Response(response))
        inScreenNavigationContext(controller, action: {
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
}
