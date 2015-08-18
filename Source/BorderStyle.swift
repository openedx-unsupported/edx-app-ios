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
    
    let cornerRadius : CGFloat
    let width : Width
    let color : UIColor?
    
    init(cornerRadius : CGFloat = OEXStyles.sharedStyles().boxCornerRadius(), width : Width = .Size(0), color : UIColor? = nil) {
        self.cornerRadius = cornerRadius
        self.width = width
        self.color = color
    }
    
    private func applyToView(view : UIView) {
        view.layer.cornerRadius = cornerRadius
        view.layer.borderWidth = width.value
        view.layer.borderColor = color?.CGColor
        if cornerRadius != 0 {
            view.clipsToBounds = true
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
