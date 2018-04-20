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

    private let trackEventsAllowed = [AnalyticsDisplayName.EnrolledCourseSuccess.rawValue, AnalyticsDisplayName.RegistrationSuccess.rawValue, AnalyticsDisplayName.UserLogin.rawValue, AnalyticsDisplayName.SharedCourse.rawValue]
    private let specialEvents = [AnalyticsDisplayName.UserLogin.rawValue, AnalyticsDisplayName.SharedCourse.rawValue]
    
    private var currentOrientationValue : String {
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
            var attributes: [String: Any] = [key_app_name : value_app_name]
            attributes[key_name] = event.name
            attributes[OEXAnalyticsKeyOrientation] =  currentOrientationValue

            if properties.count > 0 {
                attributes = attributes.concat(dictionary: properties)
            }

            if !event.label.isEmpty {
                attributes[AnswerLabelKey] = event.label
            }

            if !event.category.isEmpty {
                attributes[AnswerCategoryKey] = event.category
            }

            if let component = component {
                attributes[key_component] = component
            }
            if let courseID = event.courseID {
                attributes[key_course_id] = courseID
            }
            if let browserURL = event.openInBrowserURL {
                attributes[key_open_in_browser] = browserURL
            }

            if specialEvents.contains(event.displayName) {
                trackSpecialEvent(event: event, additionalInfo: attributes)
            }
            else {
                Answers.logCustomEvent(withName: event.displayName, customAttributes: attributes)
            }
        }
    }

    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {}

    private func trackSpecialEvent(event: OEXAnalyticsEvent, additionalInfo: [String : Any]) {
        switch event.displayName {
        case AnalyticsDisplayName.UserLogin.rawValue:
            // remove values from parameters those will be sending in special params
            var attributes = additionalInfo
            attributes.removeValue(forKey: key_method)

            if let method = additionalInfo[key_method] {
                Answers.logLogin(withMethod: method as? String, success: true, customAttributes: attributes)
            }
            break
        case AnalyticsDisplayName.SharedCourse.rawValue:
            let method = additionalInfo["type"] as? String
            let name = additionalInfo[key_name] as? String
            let category = additionalInfo[AnswerCategoryKey] as? String
            let courseID = additionalInfo[key_course_id] as? String

            // remove values from parameters those will be sending in special params
            var attributes = additionalInfo
            attributes.removeValue(forKey: "type")
            attributes.removeValue(forKey: key_name)
            attributes.removeValue(forKey: AnswerCategoryKey)
            attributes.removeValue(forKey: key_course_id)

            Answers.logShare(withMethod: method, contentName: name, contentType: category, contentId: courseID, customAttributes: attributes)

            break
        default:
            break
        }
    }
}

