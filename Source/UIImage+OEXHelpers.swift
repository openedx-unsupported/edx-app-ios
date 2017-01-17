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
        guard let cgImage = self.CGImage else { return self }
        let imageRef = CGImageCreateWithImageInRect(cgImage, rect)
        let cropped = UIImage(CGImage: imageRef!)
        return cropped
    }
    
    func resizedTo(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.drawInRect(CGRect(origin: CGPointZero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
    func rotateUp() -> UIImage {
        guard imageOrientation != .Up else { return self }
        
        var transform:CGAffineTransform = CGAffineTransformIdentity
        switch imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform,  CGFloat(-M_PI_2))
        case .UpMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        default:
            transform = CGAffineTransformIdentity
        }
        

        //Apply the transfrom to a graphics context and redraw the image
        UIGraphicsBeginImageContext(size)
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        drawInRect(CGRect(origin: CGPointZero, size: size))
        CGContextConcatCTM(context, transform)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? self
    }
}
