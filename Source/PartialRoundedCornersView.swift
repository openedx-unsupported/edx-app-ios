//
//  PartialRoundedCornersView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 19/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation


class PartialRoundedCornersView : UIView {
    
    var maskShapeLayer : CAShapeLayer?

    func makeRoundedCornersForCorners(corners : UIRectCorner) {
        let cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSizeMake(cornerRadius, cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.CGPath
        self.layer.mask = maskLayer
        self.maskShapeLayer = maskLayer
    }
    
    func removeRoundCorners() {
        self.layer.mask = nil
        maskShapeLayer = nil
    }

}