//
//  CourseDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseDataManager: NSObject {
    
    private var queriers : [String:CourseOutlineQuerier] = [:]
    
    public func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        if let querier = queriers[courseID] {
            return querier
        }
        else {
            // TODO stop using the stub course outline
            let querier = CourseOutlineQuerier(courseID: courseID, outline : CourseOutlineTestDataFactory.freshCourseOutline(courseID))
            queriers[courseID] = querier
            return querier
        }
    }
}
