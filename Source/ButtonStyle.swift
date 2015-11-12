//
//  ButtonStyle.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class ButtonStyle  {
    private let textStyle : OEXTextStyle
    private let backgroundColor : UIColor?
    private let borderStyle : BorderStyle?
    private let contentInsets : UIEdgeInsets
    private let shadowOffset: CGSize?

    init(textStyle : OEXTextStyle, backgroundColor : UIColor?, borderStyle : BorderStyle? = nil, contentInsets : UIEdgeInsets? = nil, shadowOffset : CGSize? = nil) {
        self.textStyle = textStyle
        self.backgroundColor = backgroundColor
        self.borderStyle = borderStyle
        self.contentInsets = contentInsets ?? UIEdgeInsetsZero
        self.shadowOffset = shadowOffset
    }
    
    private func applyToButton(button : UIButton, withTitle text : String? = nil) {
        button.setAttributedTitle(textStyle.attributedStringWithText(text), forState: .Normal)
        button.applyBorderStyle(borderStyle ?? BorderStyle.clearStyle())
        // Use a background image instead of a backgroundColor so that it picks up a pressed state automatically
        button.setBackgroundImage(backgroundColor.map { UIImage.oex_imageWithColor($0) }, forState: .Normal)
        button.contentEdgeInsets = contentInsets
        if let offset = shadowOffset {
            button.layer.shadowOffset = offset
            button.layer.shadowColor = UIColor.blackColor().CGColor
            button.layer.shadowOpacity = 0.5
            button.layer.shadowRadius = 1.0
            button.layer.cornerRadius = borderStyle!.cornerRadius.value(button)
            button.layer.masksToBounds = true
            button.clipsToBounds = true

        }
    }
}

extension UIButton {
    func applyButtonStyle(style : ButtonStyle, withTitle text : String?) {
        style.applyToButton(self, withTitle: text)
    }
}