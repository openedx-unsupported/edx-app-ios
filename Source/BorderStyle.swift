//
//  BorderStyle.swift
//  edX
//
//  Created by Akiva Leffert on 6/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class BorderStyle {
    enum Width {
        case Hairline
        case Size(CGFloat)
        
        var value : CGFloat {
            switch self {
            case Hairline: return OEXStyles.dividerSize()
            case let Size(s): return s
            }
        }
    }
    
    enum Radius {
        case Circle
        case Size(CGFloat)
        
        func value(view: UIView) -> CGFloat {
            switch self {
            case Circle: return view.frame.size.height / 2.0
            case let Size(s): return s
            }
        }
    }
    
    let cornerRadius : Radius
    let width : Width
    let color : UIColor?
    
    init(cornerRadius : Radius = .Size(OEXStyles.sharedStyles().boxCornerRadius()), width : Width = .Size(0), color : UIColor? = nil) {
        self.cornerRadius = cornerRadius
        self.width = width
        self.color = color
    }
    
    private func applyToView(view : UIView) {
        if let partialRoundedCournersView = view as? PartialRoundedCornersView {
            drawBorder(partialRoundedCournersView)
        }
        else {
            setBorder(view)
        }
    }
    
    private func setBorder(view : UIView) {
        let radius = cornerRadius.value(view)
        view.layer.cornerRadius = radius
        view.layer.borderWidth = width.value
        view.layer.borderColor = color?.CGColor
        if radius != 0 {
            view.clipsToBounds = true
        }
    }
    
    private func drawBorder(view : PartialRoundedCornersView) {
        
        let BORDER_LAYER_IDENTIFIER = "borderLayerIdentifier"

        if let shapeLayer = view.maskShapeLayer {
            let borderLayerMatchingClosure = { (layer : CALayer) -> Bool in
                guard let l = layer as? IdentifyableCAShapeLayer where l.identifier == BORDER_LAYER_IDENTIFIER else {
                    return false
                }
                return true
            }
            
            if let previousLayerIndex = view.layer.sublayers?.firstIndexMatching(borderLayerMatchingClosure) {
                view.layer.sublayers?.removeAtIndex(previousLayerIndex)
            }

            let shape = IdentifyableCAShapeLayer(identifier: BORDER_LAYER_IDENTIFIER)
            shape.frame = view.bounds
            shape.path = shapeLayer.path
            shape.lineWidth = width.value
            shape.strokeColor = color?.CGColor
            shape.fillColor = UIColor.clearColor().CGColor
            view.layer.addSublayer(shape)
        }
    }
    
    class func clearStyle() -> BorderStyle {
        return BorderStyle()
    }
}

extension UIView {
    func applyBorderStyle(style : BorderStyle) {
        style.applyToView(self)
    }
}
