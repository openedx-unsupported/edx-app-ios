//
//  OEXRouterTests.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX

class OEXRouterTests: XCTestCase {
    
    func testShowSplashWhenLoggedOut() {
        let config = OEXConfig(dictionary:[
            "REGISTRATION_ENABLED": true])
        let environment = TestRouterEnvironment(config: config, interface: nil)
        let router = OEXRouter(environment: environment)
        router.open(in: nil)
        XCTAssertTrue(router.t_showingLogin())
        XCTAssertEqual(router.t_navigationHierarchy().count, 0)
    }
    
    func testShowContentWhenLoggedIn() {
        let environment = TestRouterEnvironment().logInTestUser()
        let router = OEXRouter(environment: environment)
        router.open(in: nil)
        XCTAssertFalse(router.t_showingLogin())
        XCTAssertNotNil(router.t_navigationHierarchy())
    }
    
    func testShowNewAnnouncement() {
        let course = OEXCourse.accessibleTestCourse()
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockEnrollmentManager.enrollments = [UserCourseEnrollment(course: course)]
        let router = OEXRouter(environment: environment)
        router.open(in: nil)
        
        let stackLength = router.t_navigationHierarchy().count
        router.showAnnouncementsForCourse(withID: course.course_id!)
        
        // Make sure the navigation controller actions happened
        stepRunLoop()
        
        // not showing announcements so push a new screen
        XCTAssertEqual(router.t_navigationHierarchy().count, stackLength)
        
    }
    
    func testShowSameNewAnnouncement() {
        let course = OEXCourse.accessibleTestCourse()
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockEnrollmentManager.enrollments = [UserCourseEnrollment(course: course)]
        let router = OEXRouter(environment: environment)
        router.open(in: nil)
        
        // First show the announcement
        var stackLength = router.t_navigationHierarchy().count
        router.showAnnouncementsForCourse(withID: course.course_id!)
        
        // Make sure the navigation controller actions happened
        stepRunLoop()
        XCTAssertEqual(router.t_navigationHierarchy().count, stackLength)
        
        // Now try to show it again
        stackLength = router.t_navigationHierarchy().count
        router.showAnnouncementsForCourse(withID: course.course_id!)
        
        
        // Make sure the navigation controller actions happened
        stepRunLoop()
        
        // Already showing so stack length shouldn't change
        XCTAssertEqual(router.t_navigationHierarchy().count, stackLength)
    }

    func testShowDifferentNewAnnouncement() {
        let course = OEXCourse.accessibleTestCourse()
        let otherCourse = OEXCourse.accessibleTestCourse()
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockEnrollmentManager.enrollments = [UserCourseEnrollment(course: course), UserCourseEnrollment(course: otherCourse)]
        let router = OEXRouter(environment: environment)
        router.open(in: nil)
        
        // First show the announcement
        var stackLength = router.t_navigationHierarchy().count
        router.showAnnouncementsForCourse(withID: course.course_id!)
        
        // Make sure the navigation controller actions happened
        stepRunLoop()
        XCTAssertEqual(router.t_navigationHierarchy().count, stackLength)
        
        // Now try to show the next course's announcements
        stackLength = router.t_navigationHierarchy().count
        router.showAnnouncementsForCourse(withID: otherCourse.course_id!)
        
        // Make sure the navigation controller actions happened
        stepRunLoop()
        XCTAssertEqual(router.t_navigationHierarchy().count, stackLength)
        
        // Already showing so stack length shouldn't change
        XCTAssertEqual(router.t_navigationHierarchy().count, stackLength)
    }
}
