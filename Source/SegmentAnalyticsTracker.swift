//
//  SegmentAnalyticsTracker.swift
//  edX
//
//  Created by Akiva Leffert on 9/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class SegmentAnalyticsTracker : NSObject, OEXAnalyticsTracker {
    
    private let GoogleCategoryKey = "category"
    private let GoogleLabelKey = "label"
    private let GoogleActionKey = "action"
    private let firebaseTracker = FirebaseAnalyticsTracker.sharedTracker
    
    var currentOrientationValue : String {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation) ? OEXAnalyticsValueOrientationLandscape : OEXAnalyticsValueOrientationPortrait
    }

    func identifyUser(user : OEXUserDetails?) {
        if let userID = user?.userId {
            var traits : [String:AnyObject] = [:]
            if let email = user?.email {
                traits[key_email] = email
            }
            if let username = user?.username {
                traits[key_username] = username
            }
            SEGAnalytics.sharedAnalytics().identify(userID.description, traits:traits)
        }
    }
    
    func clearIdentifiedUser() {
        SEGAnalytics.sharedAnalytics().reset()
    }
    
    func trackEvent(event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : AnyObject]) {
        
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
            OEXAnalyticsKeyOrientation : currentOrientationValue
        ]
        
        info[GoogleCategoryKey] = event.category
        info[GoogleLabelKey] = event.label
        
        SEGAnalytics.sharedAnalytics().track(event.displayName, properties: info)
        
        if OEXConfig.sharedConfig().isFirebaseEnabled {
            firebaseTracker.trackEventWithName(event.displayName, parameters: info as! [String : NSObject])
        }
    }
    
    func trackScreenWithName(screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {
        
        var properties: [String:NSObject] = [
            key_context: [
                key_app_name: value_app_name
            ]
        ]
        if let value = value {
            properties[GoogleActionKey] = value
        }
        
        SEGAnalytics.sharedAnalytics().screen(screenName, properties: properties)
        
        if OEXConfig.sharedConfig().isFirebaseEnabled {
            firebaseTracker.trackEventWithName(screenName, parameters: properties)
        }
        
        // adding additional info to event
        if let info = info where info.count > 0 {
            properties = properties.concat(info)
        }
        
        let event = OEXAnalyticsEvent()
        event.displayName = screenName
        event.label = screenName
        event.category = OEXAnalyticsCategoryScreen
        event.name = OEXAnalyticsEventScreen;
        event.courseID = courseID
        trackEvent(event, forComponent: nil, withProperties: properties)
    }
}
