//
//  UIViewController+Accessibility.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension UIViewController {
    
    internal func enableBackBarButtonAccessibility() {
        self.navigationItem.backBarButtonItem?.isAccessibilityElement = true
        self.navigationItem.backBarButtonItem?.accessibilityLabel = OEXLocalizedString("ACCESSIBILITY_BACK", nil)
        println("\(self.navigationItem.backBarButtonItem) and title is \(self.navigationItem.backBarButtonItem?.accessibilityLabel)")
        
    }
}
