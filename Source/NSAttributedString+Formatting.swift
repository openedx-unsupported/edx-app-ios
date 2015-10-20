//
//  NSAttributedString+Formatting.swift
//  edX
//
//  Created by Akiva Leffert on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension OEXTextStyle {

    func apply(f : String -> String) -> (NSAttributedString -> NSAttributedString) {
        return {(s : NSAttributedString) in
            let string = f("{__param__}")
            let template = self.attributedStringWithText(string)
            return template.oex_formatWithParameters(["__param__" : s])
        }
    }
    
    @nonobjc
    func apply(f : (String, String) -> String) -> ((NSAttributedString, NSAttributedString) -> NSAttributedString) {
        return {(s1: NSAttributedString, s2: NSAttributedString) in
            let string = f("{__param1__}", "{__param2__}")
            let template = self.attributedStringWithText(string)
            return template.oex_formatWithParameters(["__param1__": s1, "__param2__": s2])
        }
    }
    
}
extension String {
    func applyStyle(style : OEXTextStyle) -> NSAttributedString {
        return style.attributedStringWithText(self)
    }
}
