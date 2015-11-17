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
    
    func assertNotificationVisibility(visible : Bool) {
        let course = OEXCourse.freshCourse()
        let config = OEXConfig(dictionary: ["PUSH_NOTIFICATIONS" : visible])
        let environment = CourseAnnouncementsViewControllerEnvironment(config: config, dataInterface: nil, router: nil, pushSettingsManager: nil)
        let controller = CourseAnnouncementsViewController(environment: environment, course: course)
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
