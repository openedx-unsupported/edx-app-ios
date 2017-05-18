//
//  CourseAnnouncementsViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 11/17/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest

@testable import edX

class CourseAnnouncementsViewControllerTests: XCTestCase {
    
    func assertNotificationVisibility(_ visible : Bool) {
        let course = OEXCourse.freshCourse()
        let config = OEXConfig(dictionary: ["PUSH_NOTIFICATIONS" : visible])
        let environment = TestRouterEnvironment(config: config)
        let controller = CourseAnnouncementsViewController(environment: environment, courseID: course.course_id!)
        let _ = controller.view // Force view to load
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        XCTAssertEqual(controller.t_showingNotificationBar, visible)
    }
    
    func testShowsNotificationBarWhenEnabled() {
        assertNotificationVisibility(true)
    }

    func testHidesNotificationBarWhenDisabled() {
        assertNotificationVisibility(false)
    }
    
}
