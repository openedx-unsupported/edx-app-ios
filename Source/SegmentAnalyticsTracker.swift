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
        
        //WARNING: Check for info file and remove debug argument
        if OEXConfig.sharedConfig().isFirebaseEnabled {
            FIRAnalytics.logEventWithName(event.displayName.formattedNameForFirebase(), parameters: formatedFirebaseParameters(info as! [String : NSObject]))
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
        
        //WARNING: Check for info file and remove debug argument
        if OEXConfig.sharedConfig().isFirebaseEnabled {
            FIRAnalytics.logEventWithName(screenName.formattedNameForFirebase(), parameters: formatedFirebaseParameters(properties))
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
    
    private func formatedFirebaseParameters(params: [String : NSObject]) -> [String : NSObject] {
        // Firebase only supports String or Number as value for event parameters
        // For segment edX is using three level dictionary so need to iterate all to fetch all parameters
        
        var parameters: [String : NSObject] = [:]
        for (key, value) in params {
            if value.isKindOfClass(NSDictionary) {
                if let innerDict = value as? [String: NSObject] {
                    for (innerKey, innerValue) in innerDict {
                        if let deepDict = innerValue as? [String: NSObject] {
                            for (deepKey, deepValue) in deepDict {
                                parameters[deepKey.formattedNameForFirebase()] = deepValue
                            }
                        }
                        else {
                            parameters[innerKey.formattedNameForFirebase()] = innerValue
                        }
                        
                    }
                }
            }
            else {
                parameters[key.formattedNameForFirebase()] = value
            }
        }
        
        //WARNING: Remove these logs after implementation 
//        print("properties: \(params)")
//        print("\n\nparameters: \(parameters)")
        
        return parameters
    }
    
}

private extension String {
    func formattedNameForFirebase()-> String {
        var string = replace(" ", replacement: "_")
        string = string.replace("-", replacement: "_")
        string = string.replace(":", replacement: "_")
        string = string.replace("__", replacement: "_")
        
        
        return string
    }
    
    private func replace(string:String, replacement:String) -> String {
        return self.stringByReplacingOccurrencesOfString(string, withString: replacement, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}
