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
        return UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) ? OEXAnalyticsValueOrientationLandscape : OEXAnalyticsValueOrientationPortrait
    }
    
    //Skipping these keys for Firebase analytics
    private let keysToSkip = [key_target_url, OEXAnalyticsKeyBlockID, "url"]
    
    func identifyUser(_ user : OEXUserDetails?) {
        FIRAnalytics.setUserID(user?.userId?.stringValue)
    }
    
    func clearIdentifiedUser() {
        FIRAnalytics.setUserID(nil)
    }
    
    func trackEvent(_ event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : Any]) {
        
        // track event
        var parameters: [String: NSObject] = [key_app_name : value_app_name as NSObject]
        parameters[OEXAnalyticsKeyOrientation] =  currentOrientationValue as NSObject
        
        if properties.count > 0 {
            parameters = parameters.concat(dictionary: properties as! [String : NSObject])
        }
        if let component = component {
            parameters[key_component] = component as NSObject
        }
        if let courseID = event.courseID {
            parameters[key_course_id] = courseID as NSObject
        }
        
        parameters[key_name] =  event.name as NSObject
        
        var formattedParameters = [String: NSObject]()
        formatParamatersForFirebase(params: parameters, formattedParams: &formattedParameters)
        FIRAnalytics.logEvent(withName: formattedKeyForFirebase(key: event.displayName), parameters: formattedParameters)
        
    }
    
    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {
        var properties: [String:NSObject] = [:]
        if let value = value {
            properties["action"] = value as NSObject
        }
        
        // adding additional info to event
        if let info = info, info.count > 0 {
            properties = properties.concat(dictionary: info as [String : NSObject])
        }
        
        let event = OEXAnalyticsEvent()
        event.displayName = screenName
        event.name = OEXAnalyticsEventScreen;
        event.courseID = courseID
        trackEvent(event, forComponent: nil, withProperties: properties)
    }
    
    private func formatParamatersForFirebase(params: [String : NSObject], formattedParams: inout [String: NSObject]) {
        // Firebase only supports String or Number as value for event parameters
        
        for (key, value) in params {
            if keysToSkip.contains(key) {
                continue
            }
            
            if isSplittingRequired(key: key) {
                let splitParameters = splitParameterValue(key: key, value: value as! String)
                for (splitKey, splitValue) in splitParameters {
                    formattedParams[formattedKeyForFirebase(key: splitKey)] = formattedParamValue(value: splitValue)
                }
            }
            else {
                // For firebase sending minifiedBlockID instead of blockID
                if key == FirebaseAnalyticsTracker.minifiedBlockIDKey as String {
                    formattedParams[formattedKeyForFirebase(key: OEXAnalyticsKeyBlockID)] = formattedParamValue(value: value)
                }
                else {
                    formattedParams[formattedKeyForFirebase(key: key)] = formattedParamValue(value: value)
                }
            }
        }
    }

    private func formattedParamValue(value: NSObject)-> NSObject {
        if value is NSString {
            return self.formatParamValue(value: value as! String) as NSObject
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
        
        let charSet = NSMutableCharacterSet(charactersIn: "_.")
        charSet.formUnion(with: NSCharacterSet.alphanumerics)
        string = string.components(separatedBy: (charSet.inverted)).joined(separator: "_")
        while string.contains("__")
        {
            string = string.replace(string: "__", replacement: "_")
        }
        
        return string
    }
    
    private func formatParamValue(value: String)-> String {
        var formattedValue = value
        
        // Firebase only supports 100 characters for parameter value
        if formattedValue.count > MaxParameterValueCharacters {
            let index = formattedValue.index(formattedValue.startIndex, offsetBy: MaxParameterValueCharacters)
            formattedValue = formattedValue.substring(to: index)
        }
        
        return formattedValue
    }
    
    func splitParameterValue(key: String, value: String)-> [String : NSObject]{
        // Only using last identifier
        let components = value.components(separatedBy:"@")
        return [key: components.last! as NSObject]
    }
}

extension String {
    
    func replace(string:String, replacement:String) -> String {
        return self.replacingOccurrences(of: string, with: replacement, options: NSString.CompareOptions.literal, range: nil)
    }
    
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
}
