//
//  CourseDashboardViewControllerTests.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

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

    func discussionsVisibleWhenEnabled(enabled: Bool) -> Bool {
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnabled: enabled)
        let environment = CourseDashboardViewControllerEnvironment(analytics : nil, config: config, networkManager: nil, router: nil)
        let controller = CourseDashboardViewController(environment: environment, course: OEXCourse.freshCourse())
        
        controller.prepareTableViewData()
        
        return controller.t_canVisitDiscussions()
    }
    
    func testDiscussionsEnabled() {
        XCTAssertTrue(discussionsVisibleWhenEnabled(true), "Discussion should be enabled for this test")
    }

    func testDiscussionsDisabled() {
        XCTAssertFalse(discussionsVisibleWhenEnabled(false), "Discussion should be disabled for this test")
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
        let tracker = OEXMockAnalyticsTracker()
        analytics.addTracker(tracker)
        let environment = CourseDashboardViewControllerEnvironment(analytics: analytics, config: nil, networkManager: nil, router: nil)
        let controller = CourseDashboardViewController(environment: environment, course: course)
        let window = UIWindow()
        window.makeKeyAndVisible()
        window.rootViewController = controller
        XCTAssertEqual(tracker.observedEvents.count, 1)
        let event = tracker.observedEvents[0] as? OEXMockAnalyticsScreenRecord
        XCTAssertNotNil(event)
        XCTAssertEqual(event!.screenName, OEXAnalyticsScreenCourseDashboard)
    }

}
