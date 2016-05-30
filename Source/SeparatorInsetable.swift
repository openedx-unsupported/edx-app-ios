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
}

extension UITableViewCell : SeparatorInsetable {
}

// In Landscape mode applyStandardSeparatorInsets not shows desired reqults
// Use ZeroMarginsTableViewCell for full separator line in both Portrait and LandScape mode
class ZeroMarginsTableViewCell: UITableViewCell {
    override var layoutMargins: UIEdgeInsets {
        set{}
        get { return UIEdgeInsetsZero}
    }
}

class ZeroMarginsTableView: UITableView {
    override var layoutMargins: UIEdgeInsets {
        set{}
        get { return UIEdgeInsetsZero}
    }
}