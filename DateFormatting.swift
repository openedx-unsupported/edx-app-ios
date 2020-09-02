//
//  DateFormatting.swift
//  edX
//
//  Created by Saeed Bashir on 7/20/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

private let StandardDateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
private let SecondaryDateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
private let StandardDateFormatMicroseconds = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"

/// Time zone set by UserPreferenceAPI
/// The standard date format used all across the edX Platform. Standard ISO 8601
open class DateFormatting: NSObject {
    
    /// Formats a time interval for display as a video duration like 23:35 or 01:14:33
    @objc open class func formatSeconds(asVideoLength totalSeconds: TimeInterval) -> String {
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        let minutes = Int((totalSeconds / 60).truncatingRemainder(dividingBy: 60))
        let hours = Int(totalSeconds / 3600)
        if hours == 0 {
            return String(format:"%02d:%02d", minutes, seconds)
        }
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// Converts a string in standard ISO8601 format to a date
    @objc open class func date(withServerString dateString: String?, timeZoneIdentifier: String? = nil) -> NSDate? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = StandardDateFormat
        if let identifier = timeZoneIdentifier {
            formatter.timeZone = TimeZone(identifier: identifier)
        } else {
            formatter.timeZone = TimeZone(abbreviation: "GMT")
        }
        
        var result = formatter.date(from: dateString)
        if result == nil {
            // Some APIs return fractional microseconds instead of seconds
            formatter.dateFormat = StandardDateFormatMicroseconds
            result = formatter.date(from: dateString)
        }
        
        return result as NSDate?
    }
    
    /// Format like April 11 or January 23
    open class func format(asMonthDayString date: NSDate?) -> String? {
        guard let date = date else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd"
        return formatter.string(from: date as Date)
    }
    
    /// Format like April 11, 2013
    @objc open class func format(asMonthDayYearString date: NSDate?) -> String? {
        guard let date = date else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        
        return formatter.string(from: date as Date)
    }
    
    open class func format(asDateMonthYearString date: NSDate) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return formatter.string(from: date as Date)
    }
    
    /// Get current date in the formatted way
    @objc open class func serverString(withDate date: NSDate?) -> String? {
        guard let date = date else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = StandardDateFormat
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        
        return formatter.string(from: date as Date)
    }
    
    open class func getDate(withFormat format: String, date: Date) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let dateString = formatter.string(from: date )
        let formattedDate = formatter.date(from: dateString) ?? date

        return formattedDate
    }
    
    /// Format like 12:00 if same day otherwise April 11, 2013
    open class func format(asMinHourOrMonthDayYearString date: NSDate) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        let order = compareTwoDates(fromDate: getDate(withFormat: "MMM dd, yyyy", date: Date()), toDate: getDate(withFormat: "MMM dd, yyyy", date: date as Date))
        formatter.dateFormat = (order == .orderedSame) ? "HH:mm" : "MMM dd, yyyy"
        return formatter.string(from: date as Date)
    }
    
    /// Format Date like Tue, Aug, 25 2020
    /// If TimeZoneIdentifier is provided, then it is applied to fomatter
    open class func format(asWeekDayMonthDateYear date: Date, timeZoneIdentifier: String?) -> String {
        let dateFormatter = DateFormatter()
        if let timeZone = timeZoneIdentifier {
            dateFormatter.timeZone = TimeZone(identifier: timeZone)
        } else {
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        }
        dateFormatter.dateFormat = "EE, MMM, d yyyy"
        return dateFormatter.string(from: date)
    }
    
    /// Get the order of two dates comparison
    open class func compareTwoDates(fromDate date: Date, toDate: Date) -> ComparisonResult {
        if(date > toDate) {
            return ComparisonResult.orderedDescending
        }
        else if (date < toDate) {
            return ComparisonResult.orderedAscending
        }
        
        return  ComparisonResult.orderedSame
    }
    
    /// Get the time zone abbreivation like PKT, EDT
    open class func timeZoneAbbriviation() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        let timeZoneAbbbreviatedDict = TimeZone.abbreviationDictionary
        var abbreviatedKey : String = ""
        if (timeZoneAbbbreviatedDict.values.contains(formatter.timeZone.identifier)) {
            for key in timeZoneAbbbreviatedDict.keys {
                if (timeZoneAbbbreviatedDict[key] == formatter.timeZone.identifier) {
                    abbreviatedKey = key
                    break
                }
            }
        }
        else
        {
            abbreviatedKey = TimeZone.current.abbreviation() ?? ""
        }
    
        return abbreviatedKey
    }
}

public extension Date {
    func stripTimeStamp(timeZoneIdentifier: String? = nil) -> Date {
        var calender = Calendar(identifier: .gregorian)
        
        if let identifier = timeZoneIdentifier, let timeZone = TimeZone(identifier: identifier) {
            calender.timeZone = timeZone
        } else  {
            calender.timeZone = NSTimeZone.default
        }
        
        let components = calender.dateComponents([.year, .month, .day], from: self)
        
        if let newDate = calender.date(from: components) {
            return newDate
        } else {
            return self
        }
    }
}
