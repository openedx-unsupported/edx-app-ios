//
//  UserPreference.swift
//  edX
//
//  Created by Kevin Kim on 7/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

public class UserPreference {
    
    enum PreferenceKeys: String, RawStringExtractable {
        case TimeZone = "time_zone"
    }

    var timeZone: String?
    
    public init?(json: JSON) {
        timeZone = json[PreferenceKeys.TimeZone].string ?? "UTC"
        
        //Set all dates to convert to user time zone chosen on web platform
        if let timeZoneName = timeZone, let validTimeZone = NSTimeZone(name: timeZoneName) {
            NSTimeZone.default = validTimeZone as TimeZone
        }
    }
    
}
