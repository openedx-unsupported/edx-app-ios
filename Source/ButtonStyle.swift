//
//  ButtonStyle.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

public class ButtonStyle : NSObject {
    var textStyle : OEXTextStyle
    var backgroundColor : UIColor?
    var borderStyle : BorderStyle?
    var contentInsets : UIEdgeInsets
    var shadow: ShadowStyle?

    init(textStyle : OEXTextStyle, backgroundColor : UIColor?, borderStyle : BorderStyle? = nil, contentInsets : UIEdgeInsets? = nil, shadow: ShadowStyle? = nil) {
        self.textStyle = textStyle
        self.backgroundColor = backgroundColor
        self.borderStyle = borderStyle
        self.contentInsets = contentInsets ?? UIEdgeInsetsZero
        self.shadow = shadow
    }
    
    private func applyToButton(button : UIButton, withTitle text : String? = nil) {
        button.setAttributedTitle(textStyle.attributedStringWithText(text), forState: .Normal)
        button.applyBorderStyle(borderStyle ?? BorderStyle.clearStyle())
        // Use a background image instead of a backgroundColor so that it picks up a pressed state automatically
        button.setBackgroundImage(backgroundColor.map { UIImage.oex_imageWithColor($0) }, forState: .Normal)
        button.contentEdgeInsets = contentInsets

        if let shadowStyle = shadow {
            button.layer.shadowColor = shadowStyle.color.CGColor
            button.layer.shadowRadius = shadowStyle.size
            button.layer.shadowOpacity = Float(shadowStyle.opacity)
            button.layer.shadowOffset = CGSize(width: cos(CGFloat(shadowStyle.angle) / 180.0 * CGFloat(M_PI)), height: sin(CGFloat(shadowStyle.angle) / 180.0 * CGFloat(M_PI)))
        }
    }
}

extension UIButton {
    func applyButtonStyle(style : ButtonStyle, withTitle text : String?) {
        style.applyToButton(self, withTitle: text)
    }
}