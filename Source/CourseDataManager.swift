//
//  CourseDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

open class CourseDataManager: NSObject {
    
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
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) -> Void in
            observer.outlineQueriers.empty()
            observer.discussionDataManagers.empty()
        }
    }
    
    open func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return outlineQueriers.objectForKey(key: courseID) {
            let querier = CourseOutlineQuerier(courseID: courseID, interface : interface, enrollmentManager: enrollmentManager, networkManager : networkManager, session : session)
            return querier
        }
    }
    
    open func discussionManagerForCourseWithID(courseID : String) -> DiscussionDataManager {
        return discussionDataManagers.objectForKey(key: courseID) {
            let manager = DiscussionDataManager(courseID: courseID, networkManager: self.networkManager)
            return manager
        }
    }
}
