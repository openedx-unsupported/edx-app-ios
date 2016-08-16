//
//  DiscussionCommentsViewControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 6/22/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX

class DiscussionCommentsViewControllerTests: SnapshotTestCase {
    func testContent() {
        let course = OEXCourse.freshCourse()
        let thread = DiscussionTestsDataFactory.thread
        let response = DiscussionTestsDataFactory.endorsedComment
        let environment = TestRouterEnvironment().logInTestUser()
        
        let comments = [DiscussionTestsDataFactory.endorsedComment1, DiscussionTestsDataFactory.unendorsedComment]

        environment.mockNetworkManager.interceptWhenMatching({(_ : NetworkRequest<Paginated<[DiscussionComment]>>) in true }) {
            let pagination = PaginationInfo(totalCount : comments.count, pageCount : 1)
            let result = Paginated<[DiscussionComment]>(pagination: pagination, value: comments)
            return (nil, result)
        }
        
        let controller = DiscussionCommentsViewController(environment: environment, courseID : course.course_id!, responseItem: response, closed: false, thread: thread)
        controller.view.setNeedsDisplay()
        
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            stepRunLoop()
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
}
