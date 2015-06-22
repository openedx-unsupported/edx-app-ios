//
//  String+OEXFormatting.swift
//  edX
//
//  Created by Tang, Jeff on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension String {
    func textWithIconFont(iconFont: String) -> String {
        var result: String
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == .LeftToRight {
            result = iconFont + " " + self
        }
        else {
            result = self + " " + iconFont
        }
        return result
    }
    
}

extension NSMutableAttributedString {
    func setSizeForText(wholeText: String, textSizes: [String: CGFloat]) {
        for (text, size) in textSizes {
            let range = (wholeText as NSString).rangeOfString(text)
            self.addAttribute(NSFontAttributeName, value: Icon.fontWithSize(size), range: range)
        }
    }
    
}
