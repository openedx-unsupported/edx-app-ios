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
    
    let config = OEXConfig(dictionary: [
        "COURSE_ENROLLMENT": [
            "TYPE": "webview"]
        ])
    
    func testSnapshotNoCourses() {
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()
        environment.mockEnrollmentManager.enrollments = []
        let controller = EnrolledCoursesViewController(environment: environment)
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testCourseList() {
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()
        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledCoursesViewController(environment: environment)
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testSnapshotNoCoursesCourseDiscoveryDisabled() {
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockEnrollmentManager.enrollments = []
        let controller = EnrolledCoursesViewController(environment: environment)
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testCourseListCourseDiscoveryDisabled() {
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
    
    func testNewAppVersionAvailable() {
        let environment = TestRouterEnvironment().logInTestUser()
        let controller = EnrolledCoursesViewController(environment: environment)
        
        // test initial state
        XCTAssertFalse(controller.t_isShowingSnackBar)
        
        //test new version available
        let expectations = expectation(description: "new app version available")
        let removable = addNotificationObserver(observer: self, name: AppNewVersionAvailableNotification) { (_, _, removable) -> Void in
            controller.showVersionUpgradeSnackBar(string: "new app version available")
            expectations.fulfill()
        }
        
        let versionInfoController = VersionUpgradeInfoController.sharedController
        versionInfoController.populateFromHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfo as? [String : Any])
        self.waitForExpectations()
        removable.remove()
        XCTAssertTrue(controller.t_isShowingSnackBar)
        // remove version upgrade info
        versionInfoController.populateFromHeaders(httpResponseHeaders: [:])
    }
}
