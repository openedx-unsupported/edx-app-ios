//
//  UIBarButtonItem+Touchable.swift
//  edX
//
//  Created by Akiva Leffert on 6/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIBarButtonItem {
    
    // This is just an approximation and should only be used for tests
    var hasTapAction : Bool {
        if self.target != nil && self.action != nil {
            return true
        }
        
        if let button = self.customView as? UIButton {
            return (button.allControlEvents.rawValue & UIControlEvents.touchUpInside.rawValue) != 0
        }
        
        return false
    }
}
