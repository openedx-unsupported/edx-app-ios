//
//  SegmentAnalyticsTracker.swift
//  edX
//
//  Created by Akiva Leffert on 9/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class SegmentAnalyticsTracker : NSObject, OEXAnalyticsTracker {
    
    private let GoogleCategoryKey = "category";
    private let GoogleLabelKey = "label";
    
    var currentOrientationValue : String {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation) ? OEXAnalyticsValueOrientationPortrait : OEXAnalyticsValueOrientationLandscape
    }
    
    var currentOutlineModeValue : String {
        switch CourseDataManager.currentOutlineMode {
        case .Full: return OEXAnalyticsValueNavigationModeFull
        case .Video: return OEXAnalyticsValueNavigationModeVideo
        }
    }

    func identifyUser(user : OEXUserDetails) {
        if let userID = user.userId {
            var traits : [String:AnyObject] = [:]
            if let email = user.email {
                traits[key_email] = email
            }
            if let username = user.username {
                traits[key_username] = username
            }
            SEGAnalytics.sharedAnalytics().identify(userID.description, traits:traits)
        }
    }
    
    func clearIdentifiedUser() {
        SEGAnalytics.sharedAnalytics().reset()
    }
    
    func trackEvent(event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [NSObject : AnyObject]) {
        
        var context = [key_app_name : value_app_name]
        if let component = component {
            context[key_component] = component
        }
        if let courseID = event.courseID {
            context[key_course_id] = courseID
        }
        if let browserURL = event.openInBrowserURL {
            context[key_open_in_browser] = browserURL
        }
        
        var info : [String : AnyObject] = [
            key_data : properties,
            key_context : context,
            key_name : event.name,
            OEXAnalyticsKeyOrientation : currentOrientationValue,
            OEXAnalyticsKeyNavigationMode : currentOutlineModeValue
        ]
        
        if let category = event.category {
            info[GoogleCategoryKey] = category
        }
        if let label = event.label {
            info[GoogleLabelKey] = label
        }
        
        SEGAnalytics.sharedAnalytics().track(event.displayName, properties: info)
    }
    
    func trackScreenWithName(screenName: String) {
        SEGAnalytics.sharedAnalytics().screen(screenName,
            properties: [
                key_context: [
                    key_appname : value_appname
                ]
            ]
        )
    }
}