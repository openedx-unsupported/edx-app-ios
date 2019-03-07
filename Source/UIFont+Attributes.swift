//
//  UIFont+Attributes.swift
//  edX
//
//  Created by Salman on 06/12/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

extension UIFont {

    var styleAttribute: UIFont.TextStyle? {
        return fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.textStyle) as? UIFont.TextStyle
    }
    
    var isPreferredSizeLarge: Bool {
        return UIApplication.shared.isPreferredContentSizeCategoryLarge
    }
    
    var preferredFont: UIFont? {
        guard let style = styleAttribute else {
            return nil
        }
        
        return UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: preferredFontSize(textStyle: style))
    }
    
    func preferredDescriptor(name: String, size: CGFloat) -> UIFontDescriptor {
        let style = textStyle(for: size)
        let preferrredFontSize = preferredFontSize(textStyle: style)
        return UIFontDescriptor(fontAttributes: [UIFontDescriptor.AttributeName.name: name, UIFontDescriptor.AttributeName.size: preferrredFontSize, UIFontDescriptor.AttributeName.textStyle: style])
    }
    
    func preferredFont(with style: UIFont.TextStyle) -> UIFont {
         return UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: style), size: preferredFontSize(textStyle: style))
    }
    
    func preferredFontSize(descriptor: UIFontDescriptor) -> CGFloat {
        if let style = descriptor.object(forKey: UIFontDescriptor.AttributeName.textStyle) as? UIFont.TextStyle {
            return preferredFontSize(textStyle: style)
        }
        
        return preferredFontSize(textStyle: .body)
    }
    
    func preferredFontSize(textStyle: UIFont.TextStyle) -> CGFloat {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let pointSize = fontDescriptor.pointSize - dynamicSizeAdjustmentFactor(with: textStyle)
        
        switch textStyle {
        case .caption2:
            return pointSize > 19 ? 19 : pointSize
        case .caption1:
            return pointSize > 20 ? 20 : pointSize
        case .footnote:
            return pointSize > 21 ? 21 : pointSize
        case .subheadline:
            return pointSize > 24 ? 24 : pointSize
        case .callout:
            return pointSize > 24 ? 24 : pointSize
        case .body:
            return pointSize > 24 ? 24 : pointSize
        case .title3:
            return pointSize > 28 ? 28 : pointSize
        case .title2:
            return pointSize > 29 ? 29 : pointSize
        case .title1:
            return pointSize > 40 ? 40 : pointSize
        default:
            return 24
        }
    }
    
    
    // This method is a bridge between apple standard sizes and edX standard sizes.
    // For example Apple default size for callout style is 16 but edX mobile App default size is 14.
    private func dynamicSizeAdjustmentFactor(with style: UIFont.TextStyle) -> CGFloat {
        switch style {
        case .caption2, .caption1, .footnote, .callout, .title3:
            return 2
        case .subheadline:
            return 3
        case .body, .title2:
            return 1
        case .title1:
            return 4
        default:
            return 2
        }
    }
    
    // We are supporting maximum dynamic size up to XXXLarge for each style
    private func dynamicTextSize(for size: CGFloat) -> CGFloat {
        let style = textStyle(for: size)
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let pointSize = fontDescriptor.pointSize - dynamicSizeAdjustmentFactor(with: style)
        
        switch style {
        case .caption2:
            return pointSize > 19 ? 19 : pointSize
        case .caption1:
            return pointSize > 20 ? 20 : pointSize
        case .footnote:
            return pointSize > 21 ? 21 : pointSize
        case .subheadline:
            return pointSize > 24 ? 24 : pointSize
        case .callout:
            return pointSize > 24 ? 24 : pointSize
        case .body:
            return pointSize > 24 ? 24 : pointSize
        case .title3:
            return pointSize > 28 ? 28 : pointSize
        case .title2:
            return pointSize > 29 ? 29 : pointSize
        case .title1:
            return pointSize > 40 ? 40 : pointSize
        default:
            return 24
        }
    }
    
    private func textStyle(for size: CGFloat) -> UIFont.TextStyle {
        
        switch OEXTextStyle.textSize(forPointSize: Int32(size)) {
        case .xxxSmall:
            return .caption2
        case .xxSmall:
            return .caption1
        case .xSmall:
            return .footnote
        case .small:
            return .subheadline
        case .base:
            return .callout
        case .large:
            return .body
        case .xLarge:
            return .title3
        case .xxLarge:
            return .title2
        case .xxxLarge:
            return .title1
        case .xxxxLarge:
            return .title1
        }
    }
}
