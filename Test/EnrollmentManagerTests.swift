//
//  EnrollmentManagerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/26/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
@testable import edX

class EnrollmentManagerTests : XCTestCase {
    
    func testEnrollmentsLoginLogout() {
        let enrollments = [
            UserCourseEnrollment(course: OEXCourse.freshCourse()),
            UserCourseEnrollment(course: OEXCourse.freshCourse())
        ]
        let environment = TestRouterEnvironment()
        environment.mockNetworkManager.interceptWhenMatching({_ in true }) {
            return (nil, enrollments)
        }
        
        let manager = EnrollmentManager(interface: nil, networkManager: environment.networkManager)
        let feed = manager.feed
        // starts empty
        XCTAssertNil(feed.output.value)
        
        // Log in. Enrollments should load
        environment.logInTestUser()
        feed.refresh()
        waitForStream(feed.output, fireIfAlreadyLoaded: false)
        XCTAssertEqual(feed.output.value!!.count, enrollments.count)
        
        // Log out. Now enrollments should be cleared
        environment.session.closeAndClearSession()
        XCTAssertNil(feed.output.value!)
    }
    
}
