//
//  UIBezierPath+Circle.swift
//  MaterialActivityIndicator
//
//  Created by Jans Pavlovs on 13.02.18.
//  Copyright (c) 2018 Jans Pavlovs. All rights reserved.
//

import UIKit

extension UIBezierPath {
    convenience init(center: CGPoint, radius: CGFloat) {
        self.init(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(.pi * 2.0), clockwise: true)
    }
}
