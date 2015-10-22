//
//  UIImage+OEXHelpers.swift
//  edX
//
//  Created by Michael Katz on 10/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension UIImage {
    func imageCroppedToRect(rect: CGRect) -> UIImage {
        let imageRef = CGImageCreateWithImageInRect(self.CGImage, rect)
        let cropped = UIImage(CGImage: imageRef!)
        return cropped
    }
}