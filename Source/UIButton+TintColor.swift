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
        if let image = self.imageView?.image?.withRenderingMode(.alwaysTemplate) {
            self.setImage(image, for: .normal)
            self.tintColor  = color
        }
    }
}
