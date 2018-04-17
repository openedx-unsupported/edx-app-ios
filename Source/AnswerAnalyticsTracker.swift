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

    private let AnswerCategoryKey = "category"
    private let AnswerLabelKey = "label"

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
            var parameters: [String: Any] = [key_app_name : value_app_name]
            parameters[key_name] = event.name
            parameters[AnswerCategoryKey] = event.category
            parameters[OEXAnalyticsKeyOrientation] =  currentOrientationValue

            if properties.count > 0 {
                parameters = parameters.concat(dictionary: properties)
            }

            if !event.label.isEmpty {
                parameters[AnswerLabelKey] = event.label
            }

            if let component = component {
                parameters[key_component] = component
            }
            if let courseID = event.courseID {
                parameters[key_course_id] = courseID
            }
            if let browserURL = event.openInBrowserURL {
                parameters[key_open_in_browser] = browserURL
            }

            if specialEvents.contains(event.displayName) {
                trackSpecialEvent(event: event, additionalInfo: parameters)
            }
            else {
                Answers.logCustomEvent(withName: event.displayName, customAttributes: parameters)
            }
        }
    }

    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {}

    private func trackSpecialEvent(event: OEXAnalyticsEvent, additionalInfo: [String : Any]) {
        switch event.displayName {
        case AnalyticsDisplayName.UserLogin.rawValue:
            if let method = additionalInfo[key_method] {
                Answers.logLogin(withMethod: method as? String, success: true, customAttributes: additionalInfo)
            }
            break
        case AnalyticsDisplayName.SharedCourse.rawValue:
            let method = additionalInfo["type"] as? String
            let name = additionalInfo[key_name] as? String
            let category = additionalInfo[AnswerCategoryKey] as? String
            let courseID = additionalInfo[key_course_id] as? String

            // remove values from parameters those will be sending in special params
            var parameters = additionalInfo
            parameters.removeValue(forKey: "type")
            parameters.removeValue(forKey: key_name)
            parameters.removeValue(forKey: AnswerCategoryKey)
            parameters.removeValue(forKey: key_course_id)

            Answers.logShare(withMethod: method, contentName: name, contentType: category, contentId: courseID, customAttributes: parameters)

            break
        default:
            break
        }
    }
}

