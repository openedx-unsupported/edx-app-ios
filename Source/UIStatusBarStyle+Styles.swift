//
//  UIStatusBarStyle+Styles.swift
//  edX
//
//  Created by Akiva Leffert on 6/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension UIStatusBarStyle {
    init(barStyle: UIBarStyle?) {
        switch barStyle ?? OEXStyles.sharedStyles().standardNavigationBarStyle() {
        case .Default: self = .Default
        default: self = .LightContent
        }
    }
}