//
//  CourseDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let CourseOutlineModeChangedNotification = "CourseOutlineModeChangedNotification"
private let CurrentCourseOutlineModeKey = "OEXCurrentCourseOutlineMode"

private let DefaultCourseMode = CourseOutlineMode.Full

public class CourseDataManager: NSObject, CourseOutlineModeControllerDataSource {
    
    private let analytics : OEXAnalytics?
    private let interface : OEXInterface?
    private let session : OEXSession?
    private let networkManager : NetworkManager?
    private let outlineQueriers = LiveObjectCache<CourseOutlineQuerier>()
    private let discussionDataManagers = LiveObjectCache<DiscussionDataManager>()
    
    public init(analytics: OEXAnalytics?, interface : OEXInterface?, networkManager : NetworkManager?, session : OEXSession?) {
        self.analytics = analytics
        self.interface = interface
        self.networkManager = networkManager
        self.session = session
        
        super.init()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXSessionEndedNotification) { (_, observer, _) -> Void in
            observer.outlineQueriers.empty()
            observer.discussionDataManagers.empty()
            NSUserDefaults.standardUserDefaults().setObject(DefaultCourseMode.rawValue, forKey: CurrentCourseOutlineModeKey)
        }
    }
    
    public func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return outlineQueriers.objectForKey(courseID) {
            let querier = CourseOutlineQuerier(courseID: courseID, interface : self.interface, networkManager : self.networkManager, session : self.session)
            return querier
        }
    }
    
    public func discussionManagerForCourseWithID(courseID : String) -> DiscussionDataManager {
        return discussionDataManagers.objectForKey(courseID) {
            let manager = DiscussionDataManager(courseID: courseID, networkManager: self.networkManager)
            return manager
        }
    }
    
    public static var currentOutlineMode : CourseOutlineMode {
        return CourseOutlineMode(rawValue: NSUserDefaults.standardUserDefaults().stringForKey(CurrentCourseOutlineModeKey) ?? "") ?? DefaultCourseMode
    }
    
    public var currentOutlineMode : CourseOutlineMode {
        get {
            return CourseDataManager.currentOutlineMode
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue.rawValue, forKey: CurrentCourseOutlineModeKey)
            NSNotificationCenter.defaultCenter().postNotificationName(CourseOutlineModeChangedNotification, object: nil)
            analytics?.trackOutlineModeChanged(currentOutlineMode)
        }
    }
    
    func freshOutlineModeController() -> CourseOutlineModeController {
        return CourseOutlineModeController(dataSource : self)
    }
    
    public var modeChangedNotificationName : String {
        return CourseOutlineModeChangedNotification
    }
}
