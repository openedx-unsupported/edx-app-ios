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
        let courses = [OEXCourse.freshCourse(), OEXCourse.freshCourse(startInfo:OEXCourseStartDisplayInfo(date: nil, displayDate: "Eventually", type: .string)), OEXCourse.freshCourse()]
        let environment = TestRouterEnvironment().logInTestUser()
        environment.mockNetworkManager.interceptWhenMatching({(_ : NetworkRequest<Paginated<[OEXCourse]>>) in true }) {
            let pagination = PaginationInfo(totalCount : courses.count, pageCount : 1)
            let result = Paginated<[OEXCourse]>(pagination: pagination, value: courses)
            return (nil, result)
        }
        
        let controller = CourseCatalogViewController(environment: environment)
        inScreenNavigationContext(controller) {
            self.waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!.view)
        }
    }
    
}
