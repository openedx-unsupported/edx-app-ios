//
//  UIImage+Resize.swift
//  edX
//
//  Created by Michael Katz on 8/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIImage {
    
    func scaleAspectFillPinnedToTopLeftInView(view: UIView, mainThreadCompletion: (newImage: UIImage) -> ()) {
        let newImageSize = view.bounds.size
        let oldImageSize = size
        
        if newImageSize == oldImageSize {
            dispatch_async(dispatch_get_main_queue()) { mainThreadCompletion(newImage: self) }
            return
        }
        
        let heightRatio = oldImageSize.height / newImageSize.height
        let widthRatio = oldImageSize.width / newImageSize.width
        let ratio = min(heightRatio, widthRatio)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            UIGraphicsBeginImageContext(newImageSize)
            self.drawInRect(CGRectMake(0, 0, oldImageSize.width / ratio, oldImageSize.height / ratio))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            dispatch_async(dispatch_get_main_queue()) { mainThreadCompletion(newImage: newImage) }
        }
    }
}