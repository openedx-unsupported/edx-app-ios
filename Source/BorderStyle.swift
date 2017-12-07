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
        typingAttributes = OEXStyles.shared().textAreaBodyStyle.attributes
        placeholderTextColor = OEXStyles.shared().neutralLight()
        applyBorderStyle(style: OEXStyles.shared().entryFieldBorderStyle)
    }
}
