//
//  CourseCatalogViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX

class CourseCatalogViewControllerTests: SnapshotTestCase {
    
    func testSnapshotList() {
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse(startInfo:OEXCourseStartDisplayInfo(date: nil, displayDate: "Eventually", type: .String)), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockNetworkManager.interceptWhenMatching({_ in true }) {
            return (nil, courses)
        }
        
        let controller = CourseCatalogViewController(environment: environment)
        inScreenNavigationContext(controller) {
            self.waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!.view)
        }
    }
    
}
