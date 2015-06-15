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
    private var _currentOutlineMode : CourseOutlineMode = .Full
    init(querier : CourseOutlineQuerier) {
        self.querier = querier
        super.init(interface : nil, networkManager: nil)
    }
    
    override func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return querier
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