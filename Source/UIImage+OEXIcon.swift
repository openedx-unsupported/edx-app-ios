//
//  UIImage+OEXIcon.swift
//  edX
//
//  Created by Michael Katz on 8/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIImage { //OEXIcon
    class func MenuIcon() -> UIImage {
        return Icon.Menu.barButtonImage(deltaFromDefault: 0)
    }
}