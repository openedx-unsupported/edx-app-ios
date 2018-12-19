//
//  UIFont+Attributes.swift
//  edX
//
//  Created by Salman on 06/12/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

extension UIFont {

    func preferredDescriptor(name: String, size: CGFloat) -> UIFontDescriptor {
        let style = textStyle(for: size)
        let preferrredFontSize = preferredFontSize(textStyle: style)
        return UIFontDescriptor(fontAttributes: [UIFontDescriptorNameAttribute: name, UIFontDescriptorSizeAttribute: preferrredFontSize, UIFontDescriptorTextStyleAttribute: style])
    }
    
    func preferredFontSize(descriptor: UIFontDescriptor) -> CGFloat {
        if let style = descriptor.object(forKey: UIFontDescriptorTextStyleAttribute) as? UIFontTextStyle {
            return preferredFontSize(textStyle: style)
        }
        
        return preferredFontSize(textStyle: .body)
    }
    
    func preferredFontSize(textStyle: UIFontTextStyle) -> CGFloat {
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
    
    func isPreferredSizeLarge () -> Bool {
        return UIApplication.shared.isPreferredContentSizeCategoryLarge()
    }
    
    private func dynamicSizeAdjustmentFactor(with style: UIFontTextStyle) -> CGFloat {
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
    
    // We are restricting the accessibility sizes for each style,
    // otherwise the text become extra large and breaks the UI
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
    
    private func textStyle(for size: CGFloat) -> UIFontTextStyle {
        switch size {
        case 9:
            return .caption2
        case 10:
            return .caption1
        case 11:
            return .footnote
        case 12:
            return .subheadline
        case 14:
            return .callout
        case 16:
            return .body
        case 18:
            return .title3
        case 21:
            return .title2
        case 24:
            return .title1
        case 28:
            return .title1
        default:
            return .callout
        }
    }
}
