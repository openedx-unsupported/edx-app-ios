//
//  CourseDashboardViewControllerTests.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
@testable import edX

private class DashboardStubConfig: OEXConfig {
    let discussionsEnabled : Bool
    var certificatesEnabled: Bool = true
    var courseSharingEnabled: Bool = true

    init(discussionsEnabled : Bool) {
        self.discussionsEnabled = discussionsEnabled
        super.init(dictionary: [:])
    }
    
    override private func shouldEnableDiscussions() -> Bool {
        return discussionsEnabled
    }

    private override func shouldEnableCertificates() -> Bool {
        return certificatesEnabled
    }

    private override func shouldEnableCourseSharing() -> Bool {
        return courseSharingEnabled
    }
}

class CourseDashboardViewControllerTests: SnapshotTestCase {

    func discussionsVisibleWhenEnabled(configEnabled : Bool, courseHasDiscussions : Bool) -> Bool {
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnabled: configEnabled)
        let environment = TestRouterEnvironment(config: config)
        let controller = CourseDashboardViewController(environment: environment,
            course: OEXCourse.freshCourse(discussionsEnabled: courseHasDiscussions))
        
        controller.prepareTableViewData()
        
        return controller.t_canVisitDiscussions()
    }
    
    func testDiscussionsEnabled() {
        for enabledInConfig in [true, false] {
            for enabledInCourse in [true, false] {
                let expected = enabledInConfig && enabledInCourse
                let result = discussionsVisibleWhenEnabled(enabledInConfig, courseHasDiscussions: enabledInCourse)
                XCTAssertEqual(result, expected, "Expected discussion visiblity \(expected) when enabledInConfig: \(enabledInConfig), enabledInCourse:\(enabledInCourse)")
            }
        }
    }
    
    func testSnapshot() {
        let config = DashboardStubConfig(discussionsEnabled: true)
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment(config: config)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testDashboardScreenAnalytics() {
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment()
        let controller = CourseDashboardViewController(environment: environment, course: course)
        let window = UIWindow()
        window.makeKeyAndVisible()
        window.rootViewController = controller
        XCTAssertEqual(environment.eventTracker.events.count, 1)
        let event = environment.eventTracker.events.first!.asScreen
        XCTAssertNotNil(event)
        XCTAssertEqual(event!.screenName, OEXAnalyticsScreenCourseDashboard)
    }
    
    func testAccessOkay() {
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment()
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenDisplayContext(controller) {
            XCTAssertTrue(controller.t_state.isLoaded)
        }
    }
    
    func testAccessBlocked() {
        let course = OEXCourse.freshCourse(accessible: false)
        let environment = TestRouterEnvironment()
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenDisplayContext(controller) {
            XCTAssertTrue(controller.t_state.isError)
        }
    }

    func testCertificate() {
        let interface = OEXInterface()
        let courseData = OEXCourse.testData()
        let enrollment = UserCourseEnrollment(dictionary: ["certificate":["url":"test"], "course" : courseData])!
        interface.courses = [enrollment]
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnabled: true)
        let environment = TestRouterEnvironment(config: config, interface: interface)
        let controller = CourseDashboardViewController(environment: environment, course: enrollment.course)
        controller.prepareTableViewData()

        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
        XCTAssertTrue(controller.t_canVisitCertificate())
    }

    func testSharing() {
        let interface = OEXInterface()
        let courseData = OEXCourse.testData(aboutUrl: "http://www.yahoo.com")
        let enrollment = UserCourseEnrollment(dictionary: ["course" : courseData])!
        interface.courses = [enrollment]
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnabled: true)
        config.courseSharingEnabled = true
        let environment = TestRouterEnvironment(config: config, interface: interface)
        let controller = CourseDashboardViewController(environment: environment, course: enrollment.course)
        controller.prepareTableViewData()

        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
}
