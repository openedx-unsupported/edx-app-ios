//
//  OEXBannerLabel.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let arrowPadding = UIEdgeInsets(top: 3, left: 3, bottom: 3, right:6)

@IBDesignable
class OEXBannerLabel : UILabel {
    
    
    override func drawRect(rect: CGRect) {
        let bannerPath = UIBezierPath()
        bannerPath.moveToPoint(CGPointZero)
        bannerPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(rect) - arrowPadding.right, y: 0))
        bannerPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(rect), y: rect.size.height / 2.0))
        bannerPath.addLineToPoint(CGPoint(x: CGRectGetMaxX(rect) - arrowPadding.right, y: CGRectGetMaxY(rect)))
        bannerPath.addLineToPoint(CGPoint(x: 0, y: CGRectGetMaxY(rect)))
        bannerPath.addLineToPoint(CGPointZero)
        bannerPath.closePath()
        
        if isRightToLeft {
            bannerPath.applyTransform(CGAffineTransformMakeScale(-1, 0))
        }
        
        OEXStyles.sharedStyles().banner().setFill()
        bannerPath.fill()
        
        super.drawRect(rect)
    }
    
    override func drawTextInRect(rect: CGRect) {
        let newRect : CGRect
        if isRightToLeft {
            newRect = UIEdgeInsetsInsetRect(rect, arrowPadding.flippedHorizontally)
        }
        else {
            newRect = UIEdgeInsetsInsetRect(rect, arrowPadding)
        }
        super.drawTextInRect(newRect)
    }
    
    override func intrinsicContentSize() -> CGSize {
        let size = super.intrinsicContentSize()
        return CGSizeMake(size.width + 2 * arrowPadding.left + arrowPadding.right, size.height + arrowPadding.bottom + arrowPadding.top)
    }
}