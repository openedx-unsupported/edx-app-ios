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
