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
        
        if #available(iOS 9.0, *) {
            let direction = UIView.userInterfaceLayoutDirectionForSemanticContentAttribute(self.semanticContentAttribute)
            switch direction {
            case .LeftToRight: return false
            case .RightToLeft: return true
            }
        } else {
            return UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft
        }
    }
    
    static var isRTL : Bool {
        return UIView().isRightToLeft
    }
}

enum LocalizedHorizontalContentAlignment {
    case Leading
    case Center
    case Trailing
    case Fill
}

extension UIControl {
    var localizedHorizontalContentAlignment : LocalizedHorizontalContentAlignment {
        get {
            switch self.contentHorizontalAlignment {
            case .Left:
                return self.isRightToLeft ? .Trailing : .Leading
            case .Right:
                return self.isRightToLeft ? .Leading : .Trailing
            case .Center:
                return .Center
            case .Fill:
                return .Fill
            }
        }
        set {
            switch newValue {
            case .Leading:
                self.contentHorizontalAlignment = self.isRightToLeft ? .Right : .Left
            case .Trailing:
                self.contentHorizontalAlignment = self.isRightToLeft ? .Left : .Right
            case .Center:
                self.contentHorizontalAlignment = .Center
            case .Fill:
                self.contentHorizontalAlignment = .Fill
            }
        }
    }
}