//
//  DataManager+Convenience.swift
//  edX
//
//  Created by Akiva Leffert on 10/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

import edX

extension DataManager {
    convenience init(courseDataManager : CourseDataManager = MockCourseDataManager(), userProfileManager : UserProfileManager = MockUserProfileManager()) {
        self.init(courseDataManager: courseDataManager, interface: nil, userProfileManager : userProfileManager)
    }
}