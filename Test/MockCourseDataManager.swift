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
    var querier : CourseOutlineQuerier?
    var topicsManager : DiscussionDataManager?
    
    override func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return querier ?? super.querierForCourseWithID(courseID: courseID)
    }
    
    override func discussionManagerForCourseWithID(courseID : String) -> DiscussionDataManager {
        return topicsManager ?? super.discussionManagerForCourseWithID(courseID: courseID)
    }
}
