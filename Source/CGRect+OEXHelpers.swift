//
//  CGRet+OEXHelpers.swift
//  edX
//
//  Created by Michael Katz on 10/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension CGRect {
    func rectOfSizeInCenter(size: CGSize) -> CGRect {
        return CGRect(x: (width - size.width) / 2.0, y: (height - size.height) / 2.0, width: size.width, height: size.height)
    }
}