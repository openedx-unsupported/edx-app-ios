//
//  NSDate+TestDates.swift
//  edX
//
//  Created by Akiva Leffert on 2/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension Date {

    // Returns a canned date in the *current* time zone
    // Such a date can be used in snapshot tests without worrying about the tester's time zone
    static func stableTestDate() -> Date {
        var components = DateComponents()
        components.year = 2015
        components.month = 1
        components.day = 2
        components.hour = 3
        components.minute = 12
        (components as NSDateComponents).calendar = Calendar(identifier:Calendar.Identifier.gregorian)
        (components as NSDateComponents).timeZone = TimeZone.autoupdatingCurrent

        return (components as NSDateComponents).date!
    }
}
