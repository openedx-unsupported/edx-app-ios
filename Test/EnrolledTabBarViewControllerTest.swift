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

class EnrolledTabBarViewControllerTest: SnapshotTestCase {
    
    func testsnapshotEnrolledTabBarView() {
        let configDict = [
            "DISCOVERY": ["TYPE": "webview", "WEBVIEW":["BASE_URL": "https:www.testurl.com"]],
            "PROGRAM": ["ENABLED": true, "PROGRAM_URL": "https:www.testurl.com"]
        ]
        let config = OEXConfig(dictionary: configDict)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)

        inScreenNavigationContext(controller) {
            stepRunLoop()
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarViewProgramDisable() {
        let configDict = [
            "DISCOVERY": ["TYPE": "webview", "WEBVIEW":["BASE_URL": "https:www.testurl.com"]]
        ]
        let config = OEXConfig(dictionary: configDict)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarShowProfile() {
        let config = OEXConfig(dictionary: [:])
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.t_viewOnlyProfileEnabled()
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarViewDiscoveryDisable() {
        let config = OEXConfig(dictionary: [:])
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.t_viewDiscoveryDisabled()
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }

    func testsnapshotEnrolledTabBarViewOnlyCoursesEnabled() {
        let config = OEXConfig(dictionary: [:])
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.t_viewOnlyCoursesEnabled()
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
}
