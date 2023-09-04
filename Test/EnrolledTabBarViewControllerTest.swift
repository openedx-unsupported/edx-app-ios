//
//  EnrolledTabBarViewControllerTest.swift
//  edX
//
//  Created by Salman on 22/12/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class EnrolledTabBarViewControllerTest: SnapshotTestCase {
    
    func testsnapshotEnrolledTabBarView() {
        let configDict = [
            "DISCOVERY": ["TYPE": "webview", "WEBVIEW":["BASE_URL": "https:www.testurl.com"]] as [String : Any],
            "PROGRAM": ["ENABLED": true, "PROGRAM_URL": "https:www.testurl.com"]
        ]
        let config = OEXConfig(dictionary: configDict)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.switchTab(with: .courseDashboard)
        
        inScreenNavigationContext(controller) {
            stepRunLoop()
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarViewDiscovery() {
        let configDict = [
            "DISCOVERY": ["TYPE": "webview", "WEBVIEW":["BASE_URL": "https:www.testurl.com"]] as [String : Any],
            "PROGRAM": ["ENABLED": true, "PROGRAM_URL": "https:www.testurl.com"] as [String : Any]
        ] as [String : Any]
        let config = OEXConfig(dictionary: configDict)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.switchTab(with: .discovery)
        
        inScreenNavigationContext(controller) {
            stepRunLoop()
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarViewProgramDisable() {
        let configDict = [
            "DISCOVERY": ["TYPE": "webview", "WEBVIEW":["BASE_URL": "https:www.testurl.com"]] as [String : Any]
        ]
        let config = OEXConfig(dictionary: configDict)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.switchTab(with: .courseDashboard)
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarViewDiscoveryAndProgramDisable() {
        let config = OEXConfig(dictionary: [:])
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.switchTab(with: .courseDashboard)
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }

    }
    
    func testsnapshotEnrolledTabBarViewDiscoveryDisable() {
        let configDict = [
            "PROGRAM": ["ENABLED": true, "PROGRAM_URL": "https:www.testurl.com"] as [String : Any]
        ]
        let config = OEXConfig(dictionary: configDict)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.switchTab(with: .none)
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testsnapshotEnrolledTabBarProgramsView() {
        let configDict = [
            "PROGRAM": ["ENABLED": true, "PROGRAM_URL": "https:www.testurl.com"] as [String : Any]
        ]
        let config = OEXConfig(dictionary: configDict)
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        let router = OEXRouter(environment: environment)
        router.open(in: nil)

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        if let controller = controller.switchTab(with: .courseDashboard) as? LearnContainerViewController {
            controller.t_switchTo(component: .programs)
        }
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }

    func testsnapshotEnrolledTabBarViewCoursesEnabled() {
        let config = OEXConfig(dictionary: [:])
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment(config: config, interface: nil).logInTestUser()

        environment.mockEnrollmentManager.courses = courses
        let controller = EnrolledTabBarViewController(environment: environment)
        controller.switchTab(with: .courseDashboard)
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
}
