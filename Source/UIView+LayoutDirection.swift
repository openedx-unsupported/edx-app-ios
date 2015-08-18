//
//  UIView+LayoutDirection.swift
//  edX
//
//  Created by Akiva Leffert on 7/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIView {
    var isRightToLeft : Bool {
        // TODO: When we pick up iOS 9, pick up the new semantic content attribute stuff
        return UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft
    }
}

extension UIButton {
    var naturalHorizontalAlignment : UIControlContentHorizontalAlignment {
        if isRightToLeft {
            return UIControlContentHorizontalAlignment.Right
        }
        else {
            return UIControlContentHorizontalAlignment.Left
        }
    }
}