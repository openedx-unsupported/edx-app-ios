//
//  CourseDashboardAdditionalViewControllerTests.swift
//  edX
//
//  Created by Salman on 13/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
import edXCore
@testable import edX

private extension OEXConfig {
    
    convenience init(courseSharingEnabled: Bool = false, isAnnouncementsEnabled: Bool = true) {
        self.init(dictionary: [
            "COURSE_SHARING_ENABLED": courseSharingEnabled,
            "ANNOUNCEMENTS_ENABLED": isAnnouncementsEnabled,
            ]
        )
    }
}

class CourseDashboardAdditionalViewControllerTests: SnapshotTestCase {
        
    func testResourcesViewSnapshot() {
        let config = OEXConfig(courseSharingEnabled: true, isAnnouncementsEnabled: true)
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment(config: config)
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        
        let dashboardController = CourseDashboardTabBarViewController(environment: environment, courseID: course.course_id!)
        let items = dashboardController.t_items()
        var cellItems : [CourseDashboardTabBarItem] = []
        for cellItem in items {
            if(cellItem.icon == .Announcements || cellItem.icon == .Handouts) {
                cellItems.append(cellItem)
            }
        }
        let additionalController = CourseDashboardAdditionalViewController(environment: environment, cellItems: cellItems)
        inScreenNavigationContext(additionalController, action: { () -> () in
            assertSnapshotValidWithContent(additionalController.navigationController!)
        })
    }
    
}
