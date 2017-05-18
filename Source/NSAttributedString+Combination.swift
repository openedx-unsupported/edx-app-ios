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
        
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            attributedStrings = Array(attributedStrings.reversed())
        }
        
        let blankSpace = NSAttributedString(string : " ")
        let resultString = NSMutableAttributedString()
        
        for (index,attrString) in attributedStrings.enumerated() {
            if index != 0 { resultString.append(blankSpace) }
            resultString.append(attrString)
        }
        return resultString
    }
    
    func singleLineWidth() -> CGFloat {
        let boundingRect = self.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        return boundingRect.width
    }
}

extension String {
    
    static func joinInNaturalLayout(nullableStrings : [String?], separator : String = " ") -> String {
        var  strings = nullableStrings.mapSkippingNils({return $0})
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            strings = strings.reversed()
        }
        return strings.joined(separator: separator)
    }
}
