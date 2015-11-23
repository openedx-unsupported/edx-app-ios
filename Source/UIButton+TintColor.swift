//
//  UIButton+TintColor.swift
//  edX
//
//  Created by Saeed Bashir on 11/20/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

extension UIButton {
    
    public func tintColor(color: UIColor) {
        if let image = self.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate) {
            self.setImage(image, forState: .Normal)
            self.tintColor  = color
        }
    }
}