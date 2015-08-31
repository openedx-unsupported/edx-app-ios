//
//  OEXBannerLabel.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let arrowWidth: CGFloat = 6.0

@IBDesignable
class OEXBannerLabel : UILabel {
    
    
    override func drawRect(rect: CGRect) {
        let bannerPath = UIBezierPath()
        bannerPath.moveToPoint(CGPointZero)
        bannerPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(rect) - arrowWidth, y: 0))
        bannerPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(rect), y: rect.size.height / 2.0))
        bannerPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(rect) - arrowWidth, y: CGRectGetMaxY(rect)))
        bannerPath.addLineToPoint(CGPoint(x: 0, y: CGRectGetMaxY(rect)))
        bannerPath.addLineToPoint(CGPointZero)
        bannerPath.closePath()
        
        if UIApplication.isRTL() {
            bannerPath.applyTransform(CGAffineTransformMakeScale(-1, 0))
        }
        
        UIColor(red: 125/255, green: 200/255, blue: 143/255, alpha: 1.0).setFill()
        bannerPath.fill()
        
        super.drawRect(rect)
    }
}