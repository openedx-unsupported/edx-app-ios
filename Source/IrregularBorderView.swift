//
//  IrregularBorderStyle.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


struct CellPosition : OptionSet {
    let rawValue : UInt
    static let Top = CellPosition(rawValue: 1 << 0)
    static let Bottom = CellPosition(rawValue: 1 << 1)
    
    var roundedCorners : UIRectCorner {
        var result = UIRectCorner()
        if self.contains(CellPosition.Top) {
            result = result.union([.topLeft, .topRight])
        }
        if self.contains(CellPosition.Bottom) {
            result = result.union([.bottomLeft, .bottomRight])
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
        super.init(frame : CGRect.zero)
        self.addSubview(cornerMaskView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var style : IrregularBorderStyle? {
        didSet {
            if let style = style {
                let radius = style.base.cornerRadius.value(view: self)
                self.cornerMaskView.image = renderMaskWithCorners(corners: style.corners, cornerRadii: CGSize(width: radius, height: radius))
                self.mask = cornerMaskView
                self.image = renderBorderWithEdges(corners: style.corners, style : style.base)
            }
            else {
                self.mask = nil
                self.image = nil
            }
        }
    }
    
    private func renderMaskWithCorners(corners : UIRectCorner, cornerRadii : CGSize) -> UIImage {
        let size = CGSize(width: cornerRadii.width * 2 + 1, height: cornerRadii.height * 2 + 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.black.setFill()
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: size), byRoundingCorners: corners, cornerRadii: cornerRadii)
        path.fill()
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!.resizableImage(withCapInsets: UIEdgeInsets(top: cornerRadii.height, left: cornerRadii.width, bottom: cornerRadii.height, right: cornerRadii.width))
    }
    
    private func renderBorderWithEdges(corners : UIRectCorner, style : BorderStyle) -> UIImage? {
        let radius = style.cornerRadius.value(view: self)
        let size = CGSize(width: radius * 2 + 1, height: radius * 2 + 1)
        guard let color = style.color else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        color.setStroke()
        
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: size), byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        path.lineWidth = style.width.value
        path.stroke()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!.resizableImage(withCapInsets: UIEdgeInsets(top: radius, left: radius, bottom: radius, right: radius))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.mask?.frame = self.bounds
    }
}
