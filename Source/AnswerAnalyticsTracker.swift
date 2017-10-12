//
//  AnswerAnalyticsTracker.swift
//  edX
//
//  Created by Salman on 26/09/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import Crashlytics


class AnswerAnalyticsTracker: NSObject, OEXAnalyticsTracker {

    let trackEventsAllowed = [AnalyticsDisplayName.EnrolledCourseClicked.rawValue, AnalyticsDisplayName.EnrolledCourseSuccess.rawValue, AnalyticsDisplayName.CreateAccount.rawValue, AnalyticsDisplayName.RegistrationSuccess.rawValue]
    
    var currentOrientationValue : String {
        return UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) ? OEXAnalyticsValueOrientationLandscape : OEXAnalyticsValueOrientationPortrait
    }
    
    func identifyUser(_ user: OEXUserDetails?) {
        Crashlytics.sharedInstance().setUserIdentifier(user?.userId?.stringValue)
    }
    
    func clearIdentifiedUser() {
        Crashlytics.sharedInstance().setUserIdentifier(nil)
    }
    
    func trackEvent(_ event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : Any]) {
        
        if(trackEventsAllowed.contains(event.displayName)) {
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
            
            let info : [String : AnyObject] = [
                key_data : properties as AnyObject,
                key_context : context as AnyObject,
                key_name : event.name as AnyObject,
                OEXAnalyticsKeyOrientation : currentOrientationValue as AnyObject
            ]
            
            Answers.logCustomEvent(withName: event.displayName, customAttributes: info)
        }
    }
    
    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {}
    
}
