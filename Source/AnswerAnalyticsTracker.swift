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

    let trackEventsAllowed = [AnalyticsDisplayName.EnrolledCourseSuccess.rawValue, AnalyticsDisplayName.RegistrationSuccess.rawValue, AnalyticsDisplayName.UserLogin.rawValue, AnalyticsDisplayName.SharedCourse.rawValue]
    let specialEvents = [AnalyticsDisplayName.UserLogin.rawValue, AnalyticsDisplayName.SharedCourse.rawValue]
    
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

            if specialEvents.contains(event.displayName) {
                trackSpecialEvent(event: event, additionalInfo: info)
            }
            else {
                Answers.logCustomEvent(withName: event.displayName, customAttributes: info)
            }
        }
    }
    
    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {}

    private func trackSpecialEvent(event: OEXAnalyticsEvent, additionalInfo: [String : AnyObject]) {
        let properties: [String : Any]? = additionalInfo[key_data] as? [String : Any]
        switch event.displayName {
        case AnalyticsDisplayName.UserLogin.rawValue:
            if let method = properties?[key_method] {
                Answers.logLogin(withMethod: method as? String, success: true, customAttributes: additionalInfo)
            }
            break
        case AnalyticsDisplayName.SharedCourse.rawValue:
            Answers.logShare(withMethod: properties?["type"] as? String, contentName: nil, contentType: nil, contentId: nil, customAttributes: additionalInfo)
            break
        default:
            break
        }
    }
    
}
