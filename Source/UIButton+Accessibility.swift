//
//  UIButton+Accessibility.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 29/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension UIButton {
    
    public func mirrorTextToAccessibilityLabel() {
        if let text = self.titleLabel?.text {
            self.accessibilityLabel = text
        }
    }
}
