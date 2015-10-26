//
//  WrappingBorderView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

struct WrappingBorderStyle {
    let corners : UIRectCorner
    let cornerRadii : CGSize
    
    init(corners : UIRectCorner, cornerRadii : CGSize) {
        self.corners = corners
        self.cornerRadii = cornerRadii
    }
    
    init(corners : UIRectCorner, radius : CGFloat) {
        self.init(corners: corners, cornerRadii: CGSize(width: radius, height: radius))
    }
}

class WrappingBorderView : UIView {
    
    let cornerMaskView = UIImageView()
    
    init() {
        super.init(frame : CGRectZero)
        self.addSubview(cornerMaskView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var style : WrappingBorderStyle? {
        didSet {
            if let style = style {
                self.cornerMaskView.image = renderMaskWithEdges(style.corners, cornerRadii: style.cornerRadii)
                self.maskView = cornerMaskView
            }
            else {
                self.maskView = nil
            }
        }
    }
    
    
    func renderMaskWithEdges(corners : UIRectCorner, cornerRadii : CGSize) -> UIImage {
        let size = CGSizeMake(cornerRadii.width * 2 + 1, cornerRadii.height * 2 + 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.blackColor().setFill()
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPointZero, size: size), byRoundingCorners: corners, cornerRadii: cornerRadii)
        path.fill()
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result.resizableImageWithCapInsets(UIEdgeInsets(top: cornerRadii.height, left: cornerRadii.width, bottom: cornerRadii.height, right: cornerRadii.width))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.maskView?.frame = self.bounds
    }
}
