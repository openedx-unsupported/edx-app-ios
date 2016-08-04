//
//  OEXDateFormatting+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 21/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXDateFormatting {
    
    public class func formatAsDateMonthYearStringWithDate(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        return formatter.stringFromDate(date)
    }
}