//
//  SeparatorInsetable.swift
//  edX
//
//  Created by Akiva Leffert on 7/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol SeparatorInsetable : class {
    var separatorInset : UIEdgeInsets { get set }
}

extension SeparatorInsetable where Self : UIView {
    func applyStandardSeparatorInsets() {
        self.separatorInset = UIEdgeInsetsZero
        self.preservesSuperviewLayoutMargins = false
        self.layoutMargins = UIEdgeInsetsZero
    }
    
    private var defaultEdgeInsets : UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: StandardHorizontalMargin, bottom: 0, right: 0)
    }
    
    func removeStandardSeparatorInsets() {
        self.separatorInset = defaultEdgeInsets
        self.preservesSuperviewLayoutMargins = true
        self.layoutMargins = defaultEdgeInsets
        
    }

}

extension UITableView : SeparatorInsetable {
    override public var layoutMargins: UIEdgeInsets {
        set(newlayoutMargins) {
            superview?.layoutMargins = newlayoutMargins
        }
        
        get { return UIEdgeInsetsZero}
    }
}

extension UITableViewCell : SeparatorInsetable {
    override public var layoutMargins: UIEdgeInsets {
        set(newlayoutMargins) {
            super.layoutMargins = newlayoutMargins
        }
        
        get { return UIEdgeInsetsZero}
    }
}