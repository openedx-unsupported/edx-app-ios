//
//  EnrolledCoursesViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
@testable import edX

class EnrolledCoursesViewControllerTests: SnapshotTestCase {

    func testSnapshotNoCourses() {
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockEnrollmentManager.enrollments = []
        let controller = EnrolledCoursesViewController(environment: environment)
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testCourseList() {
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledCoursesViewController(environment: environment)
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testAnalyticsEmitted() {
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockEnrollmentManager.enrollments = []
        let controller = EnrolledCoursesViewController(environment: environment)
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            let event = environment.eventTracker.events.firstObjectMatching {
                return $0.asScreen?.screenName == OEXAnalyticsScreenMyCourses
            }
            XCTAssertNotNil(event)
        }
    }

}
