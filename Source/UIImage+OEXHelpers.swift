//
//  UIImage+OEXHelpers.swift
//  edX
//
//  Created by Michael Katz on 10/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension UIImage {
    func imageCropped(toRect rect: CGRect) -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        let imageRef = cgImage.cropping(to: rect)
        let cropped = UIImage(cgImage: imageRef!)
        return cropped
    }
    
    func resizedTo(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
    func rotateUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        
        var transform:CGAffineTransform = .identity
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi/2))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi/2))
        case .upMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            transform = .identity
        }
        

        //Apply the transfrom to a graphics context and redraw the image
        UIGraphicsBeginImageContext(size)
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        context.concatenate(transform)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? self
    }
}
