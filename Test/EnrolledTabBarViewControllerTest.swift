//
//  EnrolledTabBarViewControllerTest.swift
//  edX
//
//  Created by Salman on 22/12/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
import edXCore
@testable import edX

private extension OEXConfig {
    convenience init(profilesEnabled: Bool = true) {
        self.init(dictionary: [
            "USER_PROFILES_ENABLED": profilesEnabled,
            "COURSE_ENROLLMENT": ["TYPE": "webview"]
            ])
    }
}

class EnrolledTabBarViewControllerTest: SnapshotTestCase {
    
    func testsnapshotEnrolledTabBarView() {
        let config = OEXConfig(profilesEnabled: true)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()
        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)

        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarViewProfileDisable() {
        let config = OEXConfig(profilesEnabled: false)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()
        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
}
