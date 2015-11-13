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

    // TODO remove this once navigation is enabled everywhere
    override private func shouldEnableNewCourseNavigation() -> Bool {
        return true
    }
}

class CourseDashboardViewControllerTests: SnapshotTestCase {

    func discussionsVisibleWhenEnabled(configEnabled : Bool, courseHasDiscussions : Bool) -> Bool {
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnabled: configEnabled)
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: config, networkManager: nil, router: nil, interface: nil)
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
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: config, networkManager: nil, router: nil, interface: nil)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testDashboardScreenAnalytics() {
        let course = OEXCourse.freshCourse()
        let analytics = OEXAnalytics()
        let tracker = MockAnalyticsTracker()
        analytics.addTracker(tracker)
        let environment = CourseDashboardViewControllerEnvironment(analytics: analytics, config: nil, networkManager: nil, router: nil, interface: nil)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        let window = UIWindow()
        window.makeKeyAndVisible()
        window.rootViewController = controller
        XCTAssertEqual(tracker.events.count, 1)
        let event = tracker.events.first!.asScreen
        XCTAssertNotNil(event)
        XCTAssertEqual(event!.screenName, OEXAnalyticsScreenCourseDashboard)
    }
    
    func testAccessOkay() {
        let course = OEXCourse.freshCourse()
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: nil, networkManager: nil, router: nil, interface: nil)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenDisplayContext(controller) {
            XCTAssertTrue(controller.t_state.isLoaded)
        }
    }
    
    func testAccessBlocked() {
        let course = OEXCourse.freshCourse(accessible: false)
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: nil, networkManager: nil, router: nil, interface: nil)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenDisplayContext(controller) {
            XCTAssertTrue(controller.t_state.isError)
        }
    }

    func testCertificate() {
        let interface = OEXInterface()
        let courseData = OEXCourse.testData()
        let enrollement = UserCourseEnrollment(dictionary: ["certificate":["url":"test"], "course" : courseData])
        interface.courses = [enrollement]
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnabled: true)
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: config, networkManager: nil, router: nil, interface: interface)
        let controller = CourseDashboardViewController(environment: environment, course: enrollement.course)
        controller.prepareTableViewData()

        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
        XCTAssertTrue(controller.t_canVisitCertificate())
    }

}
