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
    let interface : OEXInterface?
    let pushSettings : OEXPushSettingsManager
    
    public init(courseDataManager : CourseDataManager?, interface : OEXInterface? = nil, pushSettings : OEXPushSettingsManager = OEXPushSettingsManager()) {
        self.courseDataManager = courseDataManager ?? CourseDataManager(interface: interface)
        self.pushSettings = pushSettings
        self.interface = interface
    }
    
    convenience override init() {
        self.init(courseDataManager : nil, interface : OEXInterface.sharedInterface(), pushSettings : OEXPushSettingsManager())
    }
}
