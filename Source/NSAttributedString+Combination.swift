//
//  NSAttributedString+Combination.swift
//  edX
//
//  Created by Akiva Leffert on 6/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension NSAttributedString {
    class func joinInNaturalLayout(#before : NSAttributedString, after : NSAttributedString) -> NSAttributedString {
        let params = ["before" : before, "after" : after]
        switch UIApplication.sharedApplication().userInterfaceLayoutDirection {
        case .LeftToRight:
            return NSAttributedString(string: "{before} {after}").oex_formatWithParameters(params)
        case .RightToLeft:
            return NSAttributedString(string: "{after} {before}").oex_formatWithParameters(params)
        }
    }
}
