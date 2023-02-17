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
            case .Hairline: return OEXStyles.dividerSize()
            case let .Size(s): return s
            }
        }
    }
    
    enum Radius {
        case Circle
        case Size(CGFloat)
        
        func value(view: UIView) -> CGFloat {
            switch self {
            case .Circle: return view.frame.size.height / 2.0
            case let .Size(s): return s
            }
        }
    }
    
    static let defaultCornerRadius = OEXStyles.shared().boxCornerRadius()
    
    let cornerRadius : Radius
    let width : Width
    let color : UIColor?
    
    init(cornerRadius : Radius = .Size(BorderStyle.defaultCornerRadius), width : Width = .Size(0), color : UIColor? = nil) {
        self.cornerRadius = cornerRadius
        self.width = width
        self.color = color
    }
    
    fileprivate func applyToView(view : UIView) {
        let radius = cornerRadius.value(view: view)
        view.layer.cornerRadius = radius
        view.layer.borderWidth = width.value
        view.layer.borderColor = color?.cgColor
        if radius != 0 {
            view.clipsToBounds = true
        }
    }
    
    class func clearStyle() -> BorderStyle {
        return BorderStyle()
    }
}

extension UIView {
    func applyBorderStyle(style : BorderStyle) {
        style.applyToView(view: self)
    }
}

extension OEXPlaceholderTextView {
    func applyStandardBorderStyle() {
        textContainerInset = OEXStyles.shared().standardTextViewInsets
        typingAttributes = OEXStyles.shared().textAreaBodyStyle.attributes.attributedKeyDictionary()
        placeholderTextColor = OEXStyles.shared().neutralLight()
        applyBorderStyle(style: OEXStyles.shared().entryFieldBorderStyle)
    }
}

extension UIView {
    enum BorderSide {
        case top
        case left
        case right
        case bottom
    }
    
    func addBorders(edges: [BorderSide], color: UIColor, width: CGFloat) {
        for border in edges {
            let borderLayer = CALayer()
            borderLayer.backgroundColor = color.cgColor
            borderLayer.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            borderLayer.borderWidth = width
            
            switch border {
            case .top:
                borderLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: width)
            case .left:
                borderLayer.frame = CGRect(x: 0, y: 0, width: width, height: frame.height)
            case .right:
                borderLayer.frame = CGRect(x: frame.width - width, y: 0, width: width, height: frame.height)
            case .bottom:
                borderLayer.frame = CGRect(x: 0, y: frame.height - width, width: frame.width, height: width)
            }
            
            layer.addSublayer(borderLayer)
        }
    }
}

extension UITableViewCell {
    func addLeftAndRightBorder(color: UIColor, width: CGFloat) {
        let edges: [UIView.BorderSide] = [.left, .right]
        contentView.addBorders(edges: edges, color: color, width: width)
    }
}
