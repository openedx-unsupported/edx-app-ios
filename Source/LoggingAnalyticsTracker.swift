//
//  LoggingAnalyticsTracker.swift
//  edX
//
//  Created by Akiva Leffert on 9/11/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class LoggingAnalyticsTracker: NSObject, OEXAnalyticsTracker {
    private let ANALYTICS = "ANALYTICS"
    
    func identifyUser(_ user: OEXUserDetails?) {
        Logger.logInfo(ANALYTICS, "Identified User: \(String(describing: user))")
    }
    
    func clearIdentifiedUser() {
        Logger.logInfo(ANALYTICS, "Clear Identified User")
    }
    
    
    
    func trackEvent(_ event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : Any]) {
        Logger.logInfo(ANALYTICS, "Track Event: \(event), component: \(String(describing: component)), properties: \(properties)")
    }
    
    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {
        var message = "Track Screen Named: \(screenName)"
        if let courseID = courseID {
            message = message + ", courseID: \(courseID)"
        }
        if let value = value {
            message = message + ", value: \(value)"
        }
        
        if let info = info {
            for (key,objValue) in info {
                message = message + ", \(key): \(objValue)"
            }
        }
        
        Logger.logInfo(ANALYTICS, message)
    }
}
