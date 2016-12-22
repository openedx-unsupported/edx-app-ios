//
//  FirebaseAnalyticsTracker.swift
//  edX
//
//  Created by Saeed Bashir on 12/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

private let MaxParameterValueCharacters = 36

class FirebaseAnalyticsTracker: NSObject {
    
    static let sharedTracker = FirebaseAnalyticsTracker()
    
    func trackEventWithName(eventName: String, parameters: [String : NSObject]) {
        
        var formattedParameters = [String: NSObject]()
        
        formatParamatersForFirebase(parameters, formattedParams: &formattedParameters)
        FIRAnalytics.logEventWithName(formattedKeyForFirebase(eventName), parameters: formattedParameters)
    }
    
    private func formatParamatersForFirebase(params: [String : NSObject], inout formattedParams: [String: NSObject]) {
        // Firebase only supports String or Number as value for event parameters
        // For segment edX is using three level dictionary so need to iterate all to fetch all parameters
        
        for (key, value) in params {
            if value.isKindOfClass(NSDictionary) {
                formatParamatersForFirebase(value as! [String: NSObject], formattedParams: &formattedParams)
            }
            else if canAddParameter(key) {
                if isSplittingRequired(key) {
                    let splitParameters = splitParameterValue(key, value: value as! String)
                    for (splitKey, splitValue) in splitParameters {
                        formattedParams[formattedKeyForFirebase(splitKey)] = formattedParamValue(splitValue)
                    }
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
    
    private func canAddParameter(key: String) -> Bool {
        return (key != key_open_in_browser && key != "url")
    }
    
    private func isSplittingRequired(key: String) -> Bool {
        return (key == key_course_id || key == OEXAnalyticsKeyCourseID || key == key_module_id || key == OEXAnalyticsKeyBlockID)
    }
    
    private func splitParameterValue(key: String, value: String) -> [String: NSObject] {
        if key == key_course_id || key == OEXAnalyticsKeyCourseID {
            return parseCourseID(value)
        }
        else if key == key_module_id || key == OEXAnalyticsKeyBlockID {
            return parseModuleOrBlockID(key, value: value)
        }
        
        return [:]
    }
    
    private func formattedKeyForFirebase(key: String)-> String {
        var string = key
        if string == key_fullscreen {
            // Characters are more than 24, special case
            string = "video_fullscreen"
        }
        else if string == value_downloadmodule {
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
        
        var formattedValue = formattedKeyForFirebase(value)
        
        // removing edx.bi. from bi events
        if value.contains("edx.bi.") {
            formattedValue = formattedValue.replace("edx.bi.", replacement: "")
        }
        
        // Firebase only supports 36 characters for parameter value
        if formattedValue.characters.count > MaxParameterValueCharacters {
            formattedValue = formattedValue.substringToIndex(formattedValue.startIndex.advancedBy(MaxParameterValueCharacters))
        }
        
        return formattedValue
    }
    
    func parseCourseID(courseID: String)-> [String: NSObject] {
        // CourseID can ge greater than 36 characters so parsing it to org, course and run
        var components = courseID.componentsSeparatedByString("+")
        let componentsCount = 3
        var parts: [String: NSObject] = [:]
        let org = "org"
        let course = "course"
        let run = "run"
        
        if components.count <= 1 {
            // In old mongo course id was combined by '/'
            components = courseID.componentsSeparatedByString("/")
        }
        
        if components.count == componentsCount {
            // droping prefix
            parts[org] = components[0].componentsSeparatedByString(":").last
            parts[course] = components[1]
            parts[run] = components[2]
        }
        
        return parts
    }
    
    func parseModuleOrBlockID(key: String, value: String)-> [String : NSObject]{
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
