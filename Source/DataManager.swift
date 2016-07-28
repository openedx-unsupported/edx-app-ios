//
//  DataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class DataManager : NSObject {
    let courseDataManager : CourseDataManager
    let enrollmentManager : EnrollmentManager
    let interface : OEXInterface?
    let pushSettings : OEXPushSettingsManager
    let userProfileManager : UserProfileManager
    let userPreferenceManager: UserPreferenceManager
    
    public init(
        courseDataManager : CourseDataManager,
        enrollmentManager: EnrollmentManager,
        interface : OEXInterface?,
        pushSettings : OEXPushSettingsManager,
        userProfileManager : UserProfileManager,
        userPreferenceManager: UserPreferenceManager
        )
    {
        self.courseDataManager = courseDataManager
        self.enrollmentManager = enrollmentManager
        self.pushSettings = pushSettings
        self.interface = interface
        self.userProfileManager = userProfileManager
        self.userPreferenceManager = userPreferenceManager
    }
    
    
}

@objc public protocol DataManagerProvider {
    var dataManager : DataManager { get }
}