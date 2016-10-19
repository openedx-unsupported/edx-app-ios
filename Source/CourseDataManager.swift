//
//  CourseDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseDataManager: NSObject {
    
    private let analytics : OEXAnalytics
    private let interface : OEXInterface?
    private let enrollmentManager: EnrollmentManager
    private let session : OEXSession
    private let networkManager : NetworkManager
    private let outlineQueriers = LiveObjectCache<CourseOutlineQuerier>()
    private let discussionDataManagers = LiveObjectCache<DiscussionDataManager>()
    
    public init(analytics: OEXAnalytics, enrollmentManager: EnrollmentManager, interface : OEXInterface?, networkManager : NetworkManager, session : OEXSession) {
        self.analytics = analytics
        self.enrollmentManager = enrollmentManager
        self.interface = interface
        self.networkManager = networkManager
        self.session = session
        
        super.init()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXSessionEndedNotification) { (_, observer, _) -> Void in
            observer.outlineQueriers.empty()
            observer.discussionDataManagers.empty()
        }
    }
    
    public func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return outlineQueriers.objectForKey(courseID) {
            let querier = CourseOutlineQuerier(courseID: courseID, interface : interface, enrollmentManager: enrollmentManager, networkManager : networkManager, session : session)
            return querier
        }
    }
    
    public func discussionManagerForCourseWithID(courseID : String) -> DiscussionDataManager {
        return discussionDataManagers.objectForKey(courseID) {
            let manager = DiscussionDataManager(courseID: courseID, networkManager: self.networkManager)
            return manager
        }
    }
}
