//
//  FirebaseAnalyticsTracker.swift
//  edX
//
//  Created by Saeed Bashir on 12/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

private let MaxParameterValueCharacters = 100

class FirebaseAnalyticsTracker: NSObject, OEXAnalyticsTracker {
    
    static let minifiedBlockIDKey: NSString = "minifiedBlockID"
    
    var currentOrientationValue : String {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation) ? OEXAnalyticsValueOrientationLandscape : OEXAnalyticsValueOrientationPortrait
    }
    
    //Skipping these keys for Firebase analytics
    private let keysToSkip = [key_target_url, OEXAnalyticsKeyBlockID, "url"]
    
    func identifyUser(user : OEXUserDetails?) {
        FIRAnalytics.setUserID(user?.userId?.stringValue)
    }
    
    func clearIdentifiedUser() {
        FIRAnalytics.setUserID(nil)
    }
    
    func trackEvent(event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : AnyObject]) {
        // track event
        var parameters: [String: NSObject] = [key_app_name : value_app_name]
        parameters[OEXAnalyticsKeyOrientation] =  currentOrientationValue
        
        if properties.count > 0 {
            parameters = parameters.concat(properties as! [String : NSObject])
        }
        if let component = component {
            parameters[key_component] = component
        }
        if let courseID = event.courseID {
            parameters[key_course_id] = courseID
        }
        
        parameters[key_name] =  event.name
        
        var formattedParameters = [String: NSObject]()
        formatParamatersForFirebase(parameters, formattedParams: &formattedParameters)
        FIRAnalytics.logEventWithName(formattedKeyForFirebase(event.displayName), parameters: formattedParameters)
        
    }
    
    func trackScreenWithName(screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {
        var properties: [String:NSObject] = [:]
        if let value = value {
            properties["action"] = value
        }
        
        // adding additional info to event
        if let info = info where info.count > 0 {
            properties = properties.concat(info)
        }
        
        let event = OEXAnalyticsEvent()
        event.displayName = screenName
        event.name = OEXAnalyticsEventScreen;
        event.courseID = courseID
        trackEvent(event, forComponent: nil, withProperties: properties)
    }
    
    private func formatParamatersForFirebase(params: [String : NSObject], inout formattedParams: [String: NSObject]) {
        // Firebase only supports String or Number as value for event parameters
        
        for (key, value) in params {
            if keysToSkip.contains(key) {
                continue
            }
            
            if isSplittingRequired(key) {
                let splitParameters = splitParameterValue(key, value: value as! String)
                for (splitKey, splitValue) in splitParameters {
                    formattedParams[formattedKeyForFirebase(splitKey)] = formattedParamValue(splitValue)
                }
            }
            else {
                // For firebase sending minifiedBlockID instead of blockID
                if key == FirebaseAnalyticsTracker.minifiedBlockIDKey {
                    formattedParams[formattedKeyForFirebase(OEXAnalyticsKeyBlockID)] = formattedParamValue(value)
                }
                else {
                    formattedParams[formattedKeyForFirebase(key)] = formattedParamValue(value)
                }
            }
        }
    }

    private func formattedParamValue(value: NSObject)-> NSObject {
        if value.isKindOfClass(NSString) {
            return formatParamValue(value as! String)
        }
        
        return value
    }
    
    private func isSplittingRequired(key: String) -> Bool {
        return (key == key_module_id)
    }
    
    private func formattedKeyForFirebase(key: String)-> String {
        var string = key
        if string == value_downloadmodule {
            // Special case: separate two words
            string = "download_module"
        }
        
        let charSet = NSMutableCharacterSet(charactersInString: "_.")
        charSet.formUnionWithCharacterSet(NSCharacterSet.alphanumericCharacterSet())
        string = string.componentsSeparatedByCharactersInSet(charSet.invertedSet).joinWithSeparator("_")
        while string.contains("__")
        {
            string = string.replace("__", replacement: "_")
        }
        
        return string
    }
    
    private func formatParamValue(value: String)-> String {
        var formattedValue = value
        
        // Firebase only supports 100 characters for parameter value
        if formattedValue.characters.count > MaxParameterValueCharacters {
            formattedValue = formattedValue.substringToIndex(formattedValue.startIndex.advancedBy(MaxParameterValueCharacters))
        }
        
        return formattedValue
    }
    
    func splitParameterValue(key: String, value: String)-> [String : NSObject]{
        // Only using last identifier
        let components = value.componentsSeparatedByString("@")
        return [key: components.last!]
    }
}

extension String {
    
    func replace(string:String, replacement:String) -> String {
        return self.stringByReplacingOccurrencesOfString(string, withString: replacement, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    func contains(find: String) -> Bool{
        return self.rangeOfString(find) != nil
    }
}
