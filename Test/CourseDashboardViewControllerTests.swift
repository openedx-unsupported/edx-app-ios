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
    
    init(discussionsEnabled : Bool) {
        self.discussionsEnabled = discussionsEnabled
        super.init(dictionary: [:])
    }
    
    override private func shouldEnableDiscussions() -> Bool {
        return self.discussionsEnabled
    }
    
    // TODO remove this once navigation is enabled everywhere
    override private func shouldEnableNewCourseNavigation() -> Bool {
        return true
    }
}

class CourseDashboardViewControllerTests: SnapshotTestCase {

    func discussionsVisibleWhenEnabled(configEnabled : Bool, courseHasDiscussions : Bool) -> Bool {
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnabled: configEnabled)
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: config, networkManager: nil, router: nil)
        let controller = CourseDashboardViewController(environment: environment,
            course: OEXCourse.freshCourse(withDiscussionsEnabled: courseHasDiscussions))
        
        controller.prepareTableViewData()
        
        return controller.t_canVisitDiscussions()
    }
    
    func testDiscussionsEnabled() {
        XCTAssertTrue(discussionsVisibleWhenEnabled(true, courseHasDiscussions: true), "Discussion should be enabled for this test")
    }

    func testDiscussionsDisabled() {
        XCTAssertFalse(discussionsVisibleWhenEnabled(false, courseHasDiscussions: false), "Discussion should be disabled for this test")
        XCTAssertFalse(discussionsVisibleWhenEnabled(false, courseHasDiscussions: true), "Discussion should be disabled, discussion Config is disabled")
        XCTAssertFalse(discussionsVisibleWhenEnabled(true, courseHasDiscussions: false), "Discussion should be disabled, Course doesn't have discussions")
    }
    
    func testSnapshot() {
        let config = DashboardStubConfig(discussionsEnabled: true)
        let course = OEXCourse.freshCourse()
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: config, networkManager: nil, router: nil)
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
        let environment = CourseDashboardViewControllerEnvironment(analytics: analytics, config: nil, networkManager: nil, router: nil)
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
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: nil, networkManager: nil, router: nil)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenDisplayContext(controller) {
            XCTAssertTrue(controller.t_state.isLoaded)
        }
    }
    
    func testAccessBlocked() {
        let course = OEXCourse.freshCourse(accessible: false)
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: nil, networkManager: nil, router: nil)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        inScreenDisplayContext(controller) {
            XCTAssertTrue(controller.t_state.isError)
        }
    }

}
