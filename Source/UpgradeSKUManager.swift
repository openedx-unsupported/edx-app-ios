//
//  UpgradeSKUManager.swift
//  edX
//
//  Created by Muhammad Umer on 22/12/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

class UpgradeSKUManager {
    static let shared = UpgradeSKUManager()
    
    /// TODO: Test mapping for course ID to map with registered sku on AppStoreConnect,
    /// it will be updated with the updated mappings in future
    private lazy var skuMappings: [String : String] = {
        return [
            "course-v1:edX+DemoX+Demo_Course": "org.edx.mobile.integrationtest",
            "course-v1:DemoX+PERF101+course": "org.edx.mobile.test_product1",
            "course-v1:edX+Test101+course": "org.edx.mobile.test_product2",
            "course-v1:test2+2+2": "org.edx.mobile.test_product3",
            "course-v1:test3+test3+3": "org.edx.mobile.test_product4",
            "course-v1:fbe+99+99": "org.edx.mobile.test_product5"
        ]
    }()
    
    private init() { }
    
    func courseSku(for course: OEXCourse) -> String? {
        guard let courseID = course.course_id,
              skuMappings.keys.contains(courseID),
              let courseSku = skuMappings[courseID] else { return nil }
        return courseSku
    }
}
