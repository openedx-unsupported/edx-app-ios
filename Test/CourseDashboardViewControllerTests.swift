//
//  CourseDashboardViewControllerTests.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edXCore
@testable import edX

private extension OEXConfig {

    convenience init(discussionsEnabled : Bool, courseSharingEnabled: Bool = false, courseVideosEnabled: Bool = false) {
        self.init(dictionary: [
            "DISCUSSIONS_ENABLED": discussionsEnabled,
            "COURSE_SHARING_ENABLED": courseSharingEnabled,
            "COURSE_VIDEOS_ENABLED": courseVideosEnabled
            ]
        )
    }
}

class CourseDashboardViewControllerTests: SnapshotTestCase {
    
    func testDiscussionsEnabled() {
        for enabledInConfig in [true, false] {
            for enabledInCourse in [true, false] {
                
                let config = OEXConfig(discussionsEnabled: enabledInConfig)
                let course = OEXCourse.freshCourse(discussionsEnabled: enabledInCourse)
                let environment = TestRouterEnvironment(config: config)
                environment.mockEnrollmentManager.courses = [course]
                environment.logInTestUser()
                let controller = CourseDashboardViewController(environment: environment,
                    courseID: course.course_id!)
                
                inScreenDisplayContext(controller) {
                    waitForStream(controller.t_loaded)
                    
                    let enabled = controller.t_canVisitDiscussions()
                    
                    let expected = enabledInConfig && enabledInCourse
                    XCTAssertEqual(enabled, expected, "Expected discussion visiblity \(expected) when enabledInConfig: \(enabledInConfig), enabledInCourse:\(enabledInCourse)")
                }
            }
        }
    }
    
    func testHandoutsEnabled() {
        for hasHandoutsUrl in [true, false] {
            let config = OEXConfig(discussionsEnabled: true)
            let course = OEXCourse.freshCourse(discussionsEnabled: true, hasHandoutsUrl: hasHandoutsUrl)
            let environment = TestRouterEnvironment(config: config)
            environment.mockEnrollmentManager.courses = [course]
            environment.logInTestUser()
            let controller = CourseDashboardViewController(environment: environment,
                                                           courseID: course.course_id!)
            
            inScreenDisplayContext(controller) {
                waitForStream(controller.t_loaded)
                
                let enabled = controller.t_canVisitHandouts()
                
                let expected = hasHandoutsUrl
                XCTAssertEqual(enabled, expected, "Expected handouts visiblity \(expected) when course_handouts_empty: \(hasHandoutsUrl)")
            }
        }
    }
    
    func testSnapshot() {
        let config = OEXConfig(discussionsEnabled: true, courseSharingEnabled: true, courseVideosEnabled: true)
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment(config: config)
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testDashboardScreenAnalytics() {
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment()
        environment.mockEnrollmentManager.courses = [course]
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        inScreenDisplayContext(controller) {
            XCTAssertEqual(environment.eventTracker.events.count, 1)
            let event = environment.eventTracker.events.first!.asScreen
            XCTAssertNotNil(event)
            XCTAssertEqual(event!.screenName, OEXAnalyticsScreenCourseDashboard)
        }
    }
    
    func testAccessOkay() {
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment()
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            XCTAssertTrue(controller.t_state.isLoaded)
        }
    }
    
    func testAccessBlocked() {
        let course = OEXCourse.freshCourse(accessible: false)
        let environment = TestRouterEnvironment()
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            XCTAssertTrue(controller.t_state.isError)
        }
    }

    func testCertificate() {
        let courseData = OEXCourse.testData()
        let enrollment = UserCourseEnrollment(dictionary: ["certificate":["url":"test"], "course" : courseData])!
        let config = OEXConfig(discussionsEnabled: true)
        let environment = TestRouterEnvironment(config: config).logInTestUser()
        environment.mockEnrollmentManager.enrollments = [enrollment]
        
        let controller = CourseDashboardViewController(environment: environment, courseID: enrollment.course.course_id!)
        
        self.inScreenNavigationContext(controller, action: { () -> () in
            waitForStream(controller.t_loaded)
            self.assertSnapshotValidWithContent(controller.navigationController!)
        })
        XCTAssertTrue(controller.t_canVisitCertificate())
    }

    func testSharing() {
        let courseData = OEXCourse.testData(aboutUrl: "http://www.yahoo.com")
        let enrollment = UserCourseEnrollment(dictionary: ["course" : courseData])!
        
        let config = OEXConfig(discussionsEnabled: true, courseSharingEnabled: true)
        
        let environment = TestRouterEnvironment(config: config)
        environment.mockEnrollmentManager.enrollments = [enrollment]
        environment.logInTestUser()
        
        let controller = CourseDashboardViewController(environment: environment, courseID: enrollment.course.course_id!)
        
        self.inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            self.assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
}
