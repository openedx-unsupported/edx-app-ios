//
//  ButtonStyle.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public struct ButtonStyle  {
    var textStyle : OEXTextStyle
    var backgroundColor : UIColor?
    var borderStyle : BorderStyle?
    var contentInsets : UIEdgeInsets

    init(textStyle : OEXTextStyle, backgroundColor : UIColor?, borderStyle : BorderStyle? = nil, contentInsets : UIEdgeInsets? = nil) {
        self.textStyle = textStyle
        self.backgroundColor = backgroundColor
        self.borderStyle = borderStyle
        self.contentInsets = contentInsets ?? UIEdgeInsetsZero
    }
    
    private func applyToButton(button : UIButton, withTitle text : String? = nil) {
        button.setAttributedTitle(textStyle.attributedStringWithText(text), forState: .Normal)
        button.applyBorderStyle(borderStyle ?? BorderStyle.clearStyle())
        // Use a background image instead of a backgroundColor so that it picks up a pressed state automatically
        button.setBackgroundImage(backgroundColor.map { UIImage.oex_imageWithColor($0) }, forState: .Normal)
        button.contentEdgeInsets = contentInsets
    }
}

extension UIButton {
    func applyButtonStyle(style : ButtonStyle, withTitle text : String?) {
        style.applyToButton(self, withTitle: text)
    }
}