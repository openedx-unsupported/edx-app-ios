//
//  FirebaseAnalyticsTracker.swift
//  edX
//
//  Created by Saeed Bashir on 12/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

private let MaxParameterValueCharacters = 100

class FirebaseAnalyticsTracker: NSObject {
    
    static let sharedTracker = FirebaseAnalyticsTracker()
    static let minifiedBlockIDKey: NSString = "minifiedBlockID"
    
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
                continue
            }
            else if !canAddParameter(key) {
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
    
    private func canAddParameter(key: String) -> Bool {
        return (key != key_open_in_browser && key != "url" && key != key_target_url && key != OEXAnalyticsKeyBlockID)
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
