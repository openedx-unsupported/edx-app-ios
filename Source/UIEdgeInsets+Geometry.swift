//
//  UIEdgeInsets+Geometry.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public func + (left : UIEdgeInsets, right : UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(
        top: left.top + right.top,
        left: left.left + right.left,
        bottom: left.bottom + right.bottom,
        right: left.right + right.right
    )
}

extension UIEdgeInsets {

    var flippedHorizontally : UIEdgeInsets {
        return UIEdgeInsets(top: self.top, left: self.right, bottom: self.bottom, right: self.left)
    }
    
}