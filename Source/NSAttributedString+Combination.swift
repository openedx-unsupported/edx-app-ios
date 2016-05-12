//
//  NSAttributedString+Combination.swift
//  edX
//
//  Created by Akiva Leffert on 6/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
    class func joinInNaturalLayout(attributedStrings : [NSAttributedString]) -> NSAttributedString {
        var attributedStrings = attributedStrings
        
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
    
    func singleLineWidth() -> CGFloat {
        let boundingRect = self.boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: [.UsesLineFragmentOrigin, .UsesFontLeading], context: nil)
        
        return boundingRect.width
    }
}

extension String {
    
    static func joinInNaturalLayout(nullableStrings : [String?], separator : String = " ") -> String {
        var  strings = nullableStrings.mapSkippingNils({return $0})
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft {
            strings = strings.reverse()
        }
        return strings.joinWithSeparator(separator)
    }
}
