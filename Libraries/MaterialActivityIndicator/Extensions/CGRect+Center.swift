//
//  CGRect+Center.swift
//  MaterialActivityIndicator
//
//  Created by Jans Pavlovs on 13.02.18.
//  Copyright (c) 2018 Jans Pavlovs. All rights reserved.
//

import UIKit

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
