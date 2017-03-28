//
//  PostsViewControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 6/2/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX

class PostsViewControllerTests: SnapshotTestCase {
    func testActiveDiscussion() {
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment().logInTestUser()
        let topic = DiscussionTopic.testTopics()[0]
        let threads = [DiscussionTestsDataFactory.thread, DiscussionTestsDataFactory.unreadThread]
        
        let discussionInfo = DiscussionInfo(discussionID: nil, blackouts: [], isBlackedOut: false)
        
        environment.mockNetworkManager.interceptWhenMatching ({(_: NetworkRequest<DiscussionInfo>) in true }) {
            return (nil, discussionInfo)
        }
        
        environment.mockNetworkManager.interceptWhenMatching({(_ : NetworkRequest<Paginated<[DiscussionThread]>>) in true }) {
            let pagination = PaginationInfo(totalCount : threads.count, pageCount : 1)
            let result = Paginated<[DiscussionThread]>(pagination: pagination, value: threads)
            return (nil, result)
        }
        
        let controller = PostsViewController(environment: environment, courseID: course.course_id!, topic: topic)
        controller.view.setNeedsDisplay()
        
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            waitForStream(controller.t_loaded_pagination)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
        
    }
    
    func testBlackedOutDiscussion() {
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment().logInTestUser()
        let topic = DiscussionTopic.testTopics()[0]
        let threads = [DiscussionTestsDataFactory.thread, DiscussionTestsDataFactory.unreadThread]
        
        let discussionInfo = DiscussionInfo(discussionID: nil, blackouts: [], isBlackedOut: true)
        
        environment.mockNetworkManager.interceptWhenMatching ({(_: NetworkRequest<DiscussionInfo>) in true }) {
            return (nil, discussionInfo)
        }
        
        environment.mockNetworkManager.interceptWhenMatching({(_ : NetworkRequest<Paginated<[DiscussionThread]>>) in true }) {
            let pagination = PaginationInfo(totalCount : threads.count, pageCount : 1)
            let result = Paginated<[DiscussionThread]>(pagination: pagination, value: threads)
            return (nil, result)
        }
        
        let controller = PostsViewController(environment: environment, courseID: course.course_id!, topic: topic)
        controller.view.setNeedsDisplay()
        
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            waitForStream(controller.t_loaded_pagination)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
        
    }
}
