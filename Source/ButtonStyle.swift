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
        self.contentInsets = contentInsets ?? UIEdgeInsets.zero
        self.shadow = shadow
    }
    
    fileprivate func applyToButton(button : UIButton, withTitle text : String? = nil) {
        button.setAttributedTitle(textStyle.attributedString(withText: text), for: .normal)
        button.applyBorderStyle(style: borderStyle ?? BorderStyle.clearStyle())
        // Use a background image instead of a backgroundColor so that it picks up a pressed state automatically
        button.setBackgroundImage(backgroundColor.map { UIImage.oex_image(with: $0) }, for: .normal)
        button.contentEdgeInsets = contentInsets

        if let shadowStyle = shadow {
            button.layer.shadowColor = shadowStyle.color.cgColor
            button.layer.shadowRadius = shadowStyle.size
            button.layer.shadowOpacity = Float(shadowStyle.opacity)
            button.layer.shadowOffset = CGSize(width: cos(CGFloat(shadowStyle.angle) / 180.0 * CGFloat(Double.pi/2)), height: sin(CGFloat(shadowStyle.angle) / 180.0 * CGFloat(Double.pi/2)))
        }
    }
}

extension UIButton {
    func applyButtonStyle(style : ButtonStyle, withTitle text : String?) {
        style.applyToButton(button: self, withTitle: text)
    }
}
