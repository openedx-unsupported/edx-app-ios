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
        let direction = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute)
        switch direction {
        case .leftToRight: return false
        case .rightToLeft: return true
        }
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
            case .left:
                return self.isRightToLeft ? .Trailing : .Leading
            case .right:
                return self.isRightToLeft ? .Leading : .Trailing
            case .center:
                return .Center
            case .fill:
                return .Fill
            }
        }
        set {
            switch newValue {
            case .Leading:
                self.contentHorizontalAlignment = self.isRightToLeft ? .right : .left
            case .Trailing:
                self.contentHorizontalAlignment = self.isRightToLeft ? .left : .right
            case .Center:
                self.contentHorizontalAlignment = .center
            case .Fill:
                self.contentHorizontalAlignment = .fill
            }
        }
    }
}
