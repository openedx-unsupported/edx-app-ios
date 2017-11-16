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
    
        var cellItems : [CourseDashboardTabBarItem] = []
        var item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseHandouts, viewController: CourseHandoutsViewController(environment: environment, courseID: course.course_id!), icon: Icon.Handouts, detailText: Strings.Dashboard.courseHandoutsDetail)
            cellItems.append(item)
            item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseAnnouncements, viewController: CourseAnnouncementsViewController(environment: environment, courseID: course.course_id!), icon:Icon.Announcements, detailText: Strings.Dashboard.courseAnnouncementsDetail)
            cellItems.append(item)
        
        let additionalController = CourseDashboardAdditionalViewController(environment: environment, cellItems: cellItems)
        inScreenNavigationContext(additionalController, action: { () -> () in
            assertSnapshotValidWithContent(additionalController.navigationController!)
        })
    }
    
}
