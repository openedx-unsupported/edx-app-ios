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
    var discussionsEnabled : Bool
    
    init(discussionsEnable : Bool) {
        self.discussionsEnabled = discussionsEnable
        super.init(dictionary: [:])
    }
    
    override private func shouldEnableDiscussions() -> Bool {
        return self.discussionsEnabled
    }
}

class CourseDashboardViewControllerTests: XCTestCase {
    
    func discussionVisibleWhenEnabled(enabled: Bool) -> Bool {
        let config : DashboardStubConfig = DashboardStubConfig(discussionsEnable: enabled)
        let environment : CourseDashboardViewControllerEnvironment = CourseDashboardViewControllerEnvironment(config: config, router: nil)
        let controller : CourseDashboardViewController = CourseDashboardViewController(environment: environment, course: nil)
        
        controller.prepareTableViewData()
        
        return controller.t_canVisitDiscussions()
    }
    
    func testDiscussionsEnabled() {
        XCTAssertTrue(discussionVisibleWhenEnabled(true), "Discussion should be enabled for this test")
    }

    func testDiscussionsDisabled() {
        XCTAssertFalse(discussionVisibleWhenEnabled(false), "Discussion should be disabled for this test")
    }

}
