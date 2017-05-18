//
//  NSDate+TestDates.swift
//  edX
//
//  Created by Akiva Leffert on 2/19/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension NSDate {

    // Returns a canned date in the *current* time zone
    // Such a date can be used in snapshot tests without worrying about the tester's time zone
    static func stableTestDate() -> NSDate {
        let components = NSDateComponents()
        components.year = 2015
        components.month = 1
        components.day = 2
        components.hour = 3
        components.minute = 12
        components.calendar = Calendar(identifier:Calendar.Identifier.gregorian)
        components.timeZone = TimeZone.autoupdatingCurrent

        return components.date! as NSDate
    }
}
