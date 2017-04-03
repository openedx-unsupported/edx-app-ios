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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date as Date)
    }
}
