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
    
    var currentOrientationValue : String {
        return UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) ? OEXAnalyticsValueOrientationLandscape : OEXAnalyticsValueOrientationPortrait
    }

    func identifyUser(_ user : OEXUserDetails?) {
        if let userID = user?.userId {
            var traits : [String:AnyObject] = [:]
            if let email = user?.email {
                traits[key_email] = email as AnyObject
            }
            if let username = user?.username {
                traits[key_username] = username as AnyObject
            }
            SEGAnalytics.shared().identify(userID.description, traits:traits)
        }
    }
    
    func clearIdentifiedUser() {
        SEGAnalytics.shared().reset()
    }
    
    func trackEvent(_ event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : Any]) {
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
            key_data : properties as AnyObject,
            key_context : context as AnyObject,
            key_name : event.name as AnyObject,
            OEXAnalyticsKeyOrientation : currentOrientationValue as AnyObject
        ]
        
        info[GoogleCategoryKey] = event.category as AnyObject
        info[GoogleLabelKey] = event.label as AnyObject
        
        SEGAnalytics.shared().track(event.displayName, properties: info)
    }
    
    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {
        var properties: [String:Any] = [
            key_context: [
                key_app_name: value_app_name
            ]
        ]
        if let value = value {
            properties[GoogleActionKey] = value as NSObject
        }
        
        SEGAnalytics.shared().screen(screenName, properties: properties)
        
        // adding additional info to event
        if let info = info, info.count > 0 {
            properties = properties.concat(dictionary: info as [String : NSObject])
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
