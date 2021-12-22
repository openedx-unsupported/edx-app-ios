//
//  CoursePurchaseIDManager.swift
//  edX
//
//  Created by Muhammad Umer on 22/12/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

class CoursePurchaseIDManager {
    static let shared = CoursePurchaseIDManager()
    
    private lazy var courseMappings: [String : String] = {
        return [
            "course-v1:edX+DemoX+Demo_Course": "org.edx.mobile.integrationtest",
            "course-v1:DemoX+PERF101+course": "org.edx.mobile.test_product1",
            "course-v1:edX+Test101+course": "org.edx.mobile.test_product2",
            "course-v1:test2+2+2": "org.edx.mobile.test_product3",
            "course-v1:test3+test3+3": "org.edx.mobile.test_product4"
        ]
    }()
    
    private init() { }
    
    func purchaseID(for course: OEXCourse) -> String? {
        guard let courseID = course.course_id,
              courseMappings.keys.contains(courseID),
              let coursePurchaseID = courseMappings[courseID] else { return nil }
        
        return coursePurchaseID
    }
}
