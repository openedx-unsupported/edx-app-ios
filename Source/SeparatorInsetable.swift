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
        if #available(iOS 8.0, *) {
            self.preservesSuperviewLayoutMargins = false
            self.layoutMargins = UIEdgeInsetsZero
        }
    }

}

extension UITableView : SeparatorInsetable {
    
}

extension UITableViewCell : SeparatorInsetable {
    
}