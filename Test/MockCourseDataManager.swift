//
//  MockCourseDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit

class MockCourseDataManager : CourseDataManager {
    let querier : CourseOutlineQuerier
    init(querier : CourseOutlineQuerier) {
        self.querier = querier
        super.init(interface : nil, networkManager: nil)
    }
    
    override func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return querier
    }
}