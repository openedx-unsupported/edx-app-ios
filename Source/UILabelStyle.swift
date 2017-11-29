//
//  UILabelStyle.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 29/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

extension UILabel{
    func applyLabelDefaults() {
        isAccessibilityElement = false
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }
}
