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
    let querier : CourseOutlineQuerier?
    let topicsManager : DiscussionTopicsManager?
    
    private var _currentOutlineMode : CourseOutlineMode = .Full
    
    init(querier : CourseOutlineQuerier? = nil, topicsManager : DiscussionTopicsManager? = nil) {
        self.querier = querier
        self.topicsManager = topicsManager
        super.init(interface : nil, networkManager: nil)
    }
    
    override func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return querier ?? super.querierForCourseWithID(courseID)
    }
    
    override func discussionTopicManagerForCourseWithID(courseID: String) -> DiscussionTopicsManager {
        return topicsManager ?? super.discussionTopicManagerForCourseWithID(courseID)
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
