//
//  CGSize+Min.swift
//  MaterialActivityIndicator
//
//  Created by Jans Pavlovs on 13.02.18.
//  Copyright (c) 2018 Jans Pavlovs. All rights reserved.
//

import UIKit

extension CGSize {
    var min: CGFloat {
        return CGFloat.minimum(width, height)
    }
}
