//
//  CourseTabBarViewControllerTests.swift
//  edX
//
//  Created by Salman on 01/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
import edXCore
@testable import edX

private extension OEXConfig {
    
    convenience init(discussionsEnabled : Bool, courseSharingEnabled: Bool = false, courseVideosEnabled: Bool = false, isAnnouncementsEnabled: Bool = true) {
        self.init(dictionary: [
            "DISCUSSIONS_ENABLED": discussionsEnabled,
            "COURSE_SHARING_ENABLED": courseSharingEnabled,
            "COURSE_VIDEOS_ENABLED": courseVideosEnabled,
            "ANNOUNCEMENTS_ENABLED": isAnnouncementsEnabled
            ]
        )
    }
}

class CourseTabBarViewControllerTests: SnapshotTestCase {
    
    func testDiscussionsEnabled() {
        for enabledInConfig in [true, false] {
            for enabledInCourse in [true, false] {
                
                let config = OEXConfig(discussionsEnabled: enabledInConfig)
                let course = OEXCourse.freshCourse(discussionsEnabled: enabledInCourse)
                let environment = TestRouterEnvironment(config: config)
                environment.mockEnrollmentManager.courses = [course]
                environment.logInTestUser()
                let controller = CourseTabBarViewController(environment: environment, courseID: course.course_id!)
                
                
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
            let controller = CourseTabBarViewController(environment: environment, courseID: course.course_id!)
            
            inScreenDisplayContext(controller) {
                waitForStream(controller.t_loaded)
                
                let enabled = controller.t_canVisitHandouts()
                
                let expected = hasHandoutsUrl
                XCTAssertEqual(enabled, expected, "Expected handouts visiblity \(expected) when course_handouts_empty: \(hasHandoutsUrl)")
            }
        }
    }
    /*
    func testAnnouncementsEnabled() {
        for isAnnouncementsEnabled in [true, false] {
            let config = OEXConfig(discussionsEnabled: true, isAnnouncementsEnabled:isAnnouncementsEnabled)
            let course = OEXCourse.freshCourse(discussionsEnabled: true)
            let environment = TestRouterEnvironment(config: config)
            environment.mockEnrollmentManager.courses = [course]
            environment.logInTestUser()
            let controller = CourseTabBarViewController(environment: environment, courseID: course.course_id!)
            
            inScreenDisplayContext(controller) {
                waitForStream(controller.t_loaded)
                
                let enabled = controller.t_canVisitAnnouncements()
                
                let expected = isAnnouncementsEnabled
                XCTAssertEqual(enabled, expected, "Expected announcements visiblity \(expected) when is_announcements_enabled: \(isAnnouncementsEnabled)")
            }
        }
    }
     */
    
    func testSharing() {
        let courseData = OEXCourse.testData(aboutUrl: "http://www.yahoo.com")
        let enrollment = UserCourseEnrollment(dictionary: ["course" : courseData])!
        
        let config = OEXConfig(discussionsEnabled: true, courseSharingEnabled: true)
        
        let environment = TestRouterEnvironment(config: config)
        environment.mockEnrollmentManager.enrollments = [enrollment]
        environment.logInTestUser()
        
        let controller = CourseTabBarViewController(environment: environment, courseID: enrollment.course.course_id!)
        
        self.inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            self.assertSnapshotValidWithContent(controller.navigationController!)
        }
    }

}
