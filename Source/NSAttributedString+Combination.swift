//
//  NSAttributedString+Combination.swift
//  edX
//
//  Created by Akiva Leffert on 6/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
    class func joinInNaturalLayout(var attributedStrings : [NSAttributedString]) -> NSAttributedString {
        
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft {
            attributedStrings = Array(attributedStrings.reverse())
        }
        
        let blankSpace = NSAttributedString(string : " ")
        let resultString = NSMutableAttributedString()
        
        for (index,attrString) in attributedStrings.enumerate() {
            if index != 0 { resultString.appendAttributedString(blankSpace) }
            resultString.appendAttributedString(attrString)
        }
        return resultString
    }
}

extension String {
    
<<<<<<< HEAD
    static func joinInNaturalLayout(nullableStrings : [String?], separator : String = " ") -> String {
        var  strings = nullableStrings.mapSkippingNils({return $0})
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft {
            strings = strings.reverse()
        }
        return strings.joinWithSeparator(separator)
=======
    static func joinInNaturalLayout(var strings : [String]) -> String {
        
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft {
            strings = strings.reverse()
        }
        return strings.joinWithSeparator(" ")
>>>>>>> 382e4ef53d0f068f2488ee3e5fe5af6de2ee8b4a
    }
}
