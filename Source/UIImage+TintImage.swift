//
//  UIImage+TintImage.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 27/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIImage {

    public func tintWithColor(tintColor : UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.mainScreen().scale)
        let drawRect = CGRectMake(0, 0, self.size.width, self.size.height)
        self.drawInRect(drawRect)
        tintColor.set()
        UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
}