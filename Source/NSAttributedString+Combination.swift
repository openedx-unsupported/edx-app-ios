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
            attributedStrings = attributedStrings.reverse()
        }
        
        let blankSpace = NSAttributedString(string : " ")
        var resultString = NSMutableAttributedString()
        
        for (index,attrString) in enumerate(attributedStrings) {
            if index != 0 { resultString.appendAttributedString(blankSpace) }
            resultString.appendAttributedString(attrString)
        }
        return resultString
    }
}
