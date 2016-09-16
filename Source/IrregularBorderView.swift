//
//  IrregularBorderStyle.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


struct CellPosition : OptionSetType {
    let rawValue : UInt
    static let Top = CellPosition(rawValue: 1 << 0)
    static let Bottom = CellPosition(rawValue: 1 << 1)
    
    var roundedCorners : UIRectCorner {
        var result = UIRectCorner()
        if self.contains(CellPosition.Top) {
            result = result.union([.TopLeft, .TopRight])
        }
        if self.contains(CellPosition.Bottom) {
            result = result.union([.BottomLeft, .BottomRight])
        }
        return result
    }
}

struct IrregularBorderStyle {
    let corners : UIRectCorner
    let base : BorderStyle
    
    init(corners : UIRectCorner, base : BorderStyle) {
        self.corners = corners
        self.base = base
    }
    
    init(position : CellPosition, base : BorderStyle) {
        self.init(corners: position.roundedCorners, base: base)
    }
}

class IrregularBorderView : UIImageView {

    
    let cornerMaskView = UIImageView()
    
    init() {
        super.init(frame : CGRectZero)
        self.addSubview(cornerMaskView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var style : IrregularBorderStyle? {
        didSet {
            if let style = style {
                let radius = style.base.cornerRadius.value(self)
                self.cornerMaskView.image = renderMaskWithCorners(style.corners, cornerRadii: CGSizeMake(radius, radius))
                self.maskView = cornerMaskView
                self.image = renderBorderWithEdges(style.corners, style : style.base)
            }
            else {
                self.maskView = nil
                self.image = nil
            }
        }
    }
    
    private func renderMaskWithCorners(corners : UIRectCorner, cornerRadii : CGSize) -> UIImage {
        let size = CGSizeMake(cornerRadii.width * 2 + 1, cornerRadii.height * 2 + 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.blackColor().setFill()
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPointZero, size: size), byRoundingCorners: corners, cornerRadii: cornerRadii)
        path.fill()
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!.resizableImageWithCapInsets(UIEdgeInsets(top: cornerRadii.height, left: cornerRadii.width, bottom: cornerRadii.height, right: cornerRadii.width))
    }
    
    private func renderBorderWithEdges(corners : UIRectCorner, style : BorderStyle) -> UIImage? {
        let radius = style.cornerRadius.value(self)
        let size = CGSizeMake(radius * 2 + 1, radius * 2 + 1)
        guard let color = style.color else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        color.setStroke()
        
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPointZero, size: size), byRoundingCorners: corners, cornerRadii: CGSizeMake(radius, radius))
        path.lineWidth = style.width.value
        path.stroke()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!.resizableImageWithCapInsets(UIEdgeInsets(top: radius, left: radius, bottom: radius, right: radius))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.maskView?.frame = self.bounds
    }
}
