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
    var layoutMargins : UIEdgeInsets { get set }
    var preservesSuperviewLayoutMargins : Bool { get set }
}

// With Swift 2.0 we can just make this a protocol extension
private func applyStandardInsets(insetable : SeparatorInsetable) {
    insetable.separatorInset = UIEdgeInsetsZero
    if UIDevice.currentDevice().isOSVersionAtLeast8() {
        insetable.preservesSuperviewLayoutMargins = false
        insetable.layoutMargins = UIEdgeInsetsZero
    }
}


extension UITableViewCell : SeparatorInsetable {
    func applyStandardSeparatorInsets() {
        applyStandardInsets(self)
    }
}

extension UITableView : SeparatorInsetable {
    func applyStandardSeparatorInsets() {
        applyStandardInsets(self)
    }
}
