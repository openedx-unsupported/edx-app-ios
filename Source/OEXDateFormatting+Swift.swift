//
//  OEXDateFormatting+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 21/09/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXDateFormatting {
    
    class func formatAsDateMonthYearStringWithDate(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.stringFromDate(date)
    }
}