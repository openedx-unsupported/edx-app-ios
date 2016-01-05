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
    
    private var _currentOutlineMode : CourseOutlineMode = .Full
    
    override func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return querier ?? super.querierForCourseWithID(courseID)
    }
    
    override func discussionManagerForCourseWithID(courseID: String) -> DiscussionDataManager {
        return topicsManager ?? super.discussionManagerForCourseWithID(courseID)
    }
    
    override var currentOutlineMode : CourseOutlineMode {
        get {
            return _currentOutlineMode
        }
        set {
            _currentOutlineMode = newValue
            NSNotificationCenter.defaultCenter().postNotificationName(self.modeChangedNotificationName, object: nil)
        }
    }
}
