//
//  OEXStyles+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 25/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

struct ShadowStyle {
    let angle: Int //degrees
    let color: UIColor
    let opacity: CGFloat //0..1
    let distance: CGFloat
    let size: CGFloat

    var shadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = color.withAlphaComponent(opacity)
        shadow.shadowOffset = CGSize(width: cos(CGFloat(angle) / 180.0 * CGFloat(Double.pi)), height: sin(CGFloat(angle) / 180.0 * CGFloat(Double.pi)))
        shadow.shadowBlurRadius = size
        return shadow
    }
}

extension OEXStyles {
    
    var navigationTitleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .base, color : navigationItemTintColor())
    }
    
    var navigationButtonTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .small, color: nil)
    }
    
    private var searchBarTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralBlack())
    }
    
    @objc public func applyGlobalAppearance() {
        //Probably want to set the tintColor of UIWindow but it didn't seem necessary right now
        
        UINavigationBar.appearance().barTintColor = navigationBarColor()
        UINavigationBar.appearance().barStyle = UIBarStyle.black
        UINavigationBar.appearance().tintColor = navigationItemTintColor()
        UINavigationBar.appearance().titleTextAttributes = navigationTitleTextStyle.attributes.attributedKeyDictionary()
        
        UIBarButtonItem.appearance().setTitleTextAttributes(navigationButtonTextStyle.attributes.attributedKeyDictionary(), for: .normal)
        
        UIToolbar.appearance().tintColor = navigationItemTintColor()
        
        let style = OEXTextStyle(weight: .normal, size : .small, color : neutralBlack())
        let styleAttributes = style.attributes.attributedKeyDictionary()
        UISegmentedControl.appearance().setTitleTextAttributes(styleAttributes, for: UIControl.State.selected)
        UISegmentedControl.appearance().setTitleTextAttributes(styleAttributes, for: UIControl.State.normal)
        UISegmentedControl.appearance().tintColor = primaryXLightColor()
        
        UINavigationBar.appearance().isTranslucent = false
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.classForCoder() as! UIAppearanceContainer.Type]).defaultTextAttributes = searchBarTextStyle.attributes.attributedKeyDictionary()

        if #available(iOS 13.0, *) {
            UISegmentedControl.appearance().selectedSegmentTintColor = primaryBaseColor()
        }
    }
    
    ///**Warning:** Not from style guide. Do not add more uses
    public var progressBarTintColor : UIColor {
        return UIColor(red: CGFloat(126.0/255.0), green: CGFloat(199.0/255.0), blue: CGFloat(143.0/255.0), alpha: CGFloat(1.00))
    }
    
    public var progressBarTrackTintColor : UIColor {
        return OEXStyles.shared().neutralLight()
    }

    var standardTextViewInsets : UIEdgeInsets {
        return UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    var standardFooterHeight : CGFloat {
        return 50
    }
    
    @objc var standardVerticalMargin : CGFloat {
        return 8.0
    }
    
    var discussionsBackgroundColor : UIColor {
        return OEXStyles.shared().neutralXLight()
    }

// Standard text Styles
    
    var textAreaBodyStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralBlack())
        style.lineBreakMode = .byWordWrapping
        return style
    }
    
    func textFieldStyle(with size: OEXTextSize, color: UIColor = OEXStyles.shared().neutralXDark()) -> OEXTextStyle {
        return OEXMutableTextStyle(weight: .normal, size: size, color: color)
    }
    

// Standard button styles

    @objc var filledPrimaryButtonStyle : ButtonStyle {
        return filledButtonStyle(color: OEXStyles.shared().secondaryBaseColor())
    }

    func filledButtonStyle(color: UIColor) -> ButtonStyle {
        let buttonMargins : CGFloat = 8
        let borderStyle = BorderStyle(cornerRadius: .Size(0), width: .Size(0), color: neutralBase())
        let textStyle = OEXTextStyle(weight: .semiBold, size: .base, color: neutralWhiteT())
        return ButtonStyle(textStyle: textStyle, backgroundColor: color, borderStyle: borderStyle,
                           contentInsets : UIEdgeInsets.init(top: buttonMargins, left: buttonMargins, bottom: buttonMargins, right: buttonMargins))
    }
    
    var linkButtonStyle: ButtonStyle {
        let textStyle = OEXTextStyle(weight: .normal, size: .small, color: self.primaryBaseColor())
        return ButtonStyle(textStyle: textStyle, backgroundColor: nil)
    }
    
    var filledEmphasisButtonStyle : ButtonStyle {
        let buttonMargins : CGFloat = 12
        let result = filledPrimaryButtonStyle
        result.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        result.textStyle = result.textStyle.withSize(.xLarge)
        result.contentInsets = UIEdgeInsets.init(top: buttonMargins, left: buttonMargins, bottom: buttonMargins, right: buttonMargins)
        return result
    }
    
// Standard border styles
    var entryFieldBorderStyle : BorderStyle {
        return BorderStyle(cornerRadius: .Size(0), width: .Size(1), color: OEXStyles.shared().neutralBase())
    }
    
//Standard Divider styles
    
    var standardDividerColor : UIColor {
        return self.neutralLight()
    }
}

extension UIView {
    func applyStandardContainerViewStyle() {
        backgroundColor = OEXStyles.shared().neutralWhiteT()
        layer.cornerRadius = OEXStyles.shared().boxCornerRadius()
        layer.masksToBounds = true
    }
    
    func applyStandardContainerViewShadow() {
        layer.shadowColor = OEXStyles.shared().neutralBlack().cgColor;
        layer.shadowRadius = 1.0;
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowOpacity = 0.8;
    }
}

//Standard Search Bar styles
extension UISearchBar {
    func applyStandardStyles(withPlaceholder placeholder : String? = nil) {
        self.placeholder = placeholder
        self.showsCancelButton = false
        self.searchBarStyle = .default
        self.backgroundColor = OEXStyles.shared().neutralWhiteT()
        
    }
}

//Convenience computed properties for margins
var StandardHorizontalMargin: CGFloat {
    return OEXStyles.shared().standardHorizontalMargin()
}

var StandardVerticalMargin: CGFloat {
    return OEXStyles.shared().standardVerticalMargin
}

var StandardFooterHeight: CGFloat {
    return OEXStyles.shared().standardFooterHeight
}
