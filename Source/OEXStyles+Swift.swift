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
        shadow.shadowColor = color.colorWithAlphaComponent(opacity)
        shadow.shadowOffset = CGSize(width: cos(CGFloat(angle) / 180.0 * CGFloat(M_PI)), height: sin(CGFloat(angle) / 180.0 * CGFloat(M_PI)))
        shadow.shadowBlurRadius = size
        return shadow
    }
}

extension OEXStyles {
    
    var navigationTitleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .Base, color : navigationItemTintColor())
    }
    
    var navigationButtonTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .Small, color: nil)
    }
    
    private var searchBarTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBlack())
    }
    
    public func applyGlobalAppearance() {
        //Probably want to set the tintColor of UIWindow but it didn't seem necessary right now
        
        UINavigationBar.appearance().barTintColor = navigationBarColor()
        UINavigationBar.appearance().barStyle = UIBarStyle.Black
        UINavigationBar.appearance().tintColor = navigationItemTintColor()
        UINavigationBar.appearance().titleTextAttributes = navigationTitleTextStyle.attributes
        UIBarButtonItem.appearance().setTitleTextAttributes(navigationButtonTextStyle.attributes, forState: .Normal)
        
        UIToolbar.appearance().tintColor = navigationBarColor()
        
        let styleAttributes = OEXTextStyle(weight: .Normal, size : .Small, color : self.neutralBlack()).attributes
        UISegmentedControl.appearance().setTitleTextAttributes(styleAttributes, forState: UIControlState.Selected)
        UISegmentedControl.appearance().setTitleTextAttributes(styleAttributes, forState: UIControlState.Normal)
        UISegmentedControl.appearance().tintColor = self.primaryXLightColor()
        
        UINavigationBar.appearance().translucent = false

        if #available(iOS 9.0, *) {
            UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.classForCoder()]).defaultTextAttributes = searchBarTextStyle.attributes
        }
        else {
            //Make sure we remove UIAppearance+Swift.h+m when we drop iOS8 support
            UITextField.my_appearanceWhenContainedIn(UISearchBar.classForCoder()).defaultTextAttributes = searchBarTextStyle.attributes
        }
    }
    
    ///**Warning:** Not from style guide. Do not add more uses
    public var progressBarTintColor : UIColor {
        return UIColor(red: CGFloat(126.0/255.0), green: CGFloat(199.0/255.0), blue: CGFloat(143.0/255.0), alpha: CGFloat(1.00))
    }
    
    ///**Warning:** Not from style guide. Do not add more uses
    public var progressBarTrackTintColor : UIColor {
        return UIColor(red: CGFloat(223.0/255.0), green: CGFloat(242.0/255.0), blue: CGFloat(228.0/255.0), alpha: CGFloat(1.00))
    }


    var standardTextViewInsets : UIEdgeInsets {
        return UIEdgeInsetsMake(8, 8, 8, 8)
    }
    
    var standardFooterHeight : CGFloat {
        return 50
    }
    
    var standardVerticalMargin : CGFloat {
        return 8.0
    }
    
    var discussionsBackgroundColor : UIColor {
        return OEXStyles.sharedStyles().neutralXLight()
    }

// Standard text Styles
    
    var textAreaBodyStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
        style.lineBreakMode = .ByWordWrapping
        return style
    }

// Standard button styles

    var filledPrimaryButtonStyle : ButtonStyle {
        return filledButtonStyle(OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    var filledSecondaryButtonStyle : ButtonStyle {
        return filledButtonStyle(OEXStyles.sharedStyles().secondaryBaseColor())
    }

    func filledButtonStyle(color: UIColor) -> ButtonStyle {
        let buttonMargins : CGFloat = 8
        let borderStyle = BorderStyle()
        let textStyle = OEXTextStyle(weight: .SemiBold, size: .Base, color: self.neutralWhite())
        return ButtonStyle(textStyle: textStyle, backgroundColor: color, borderStyle: borderStyle,
                           contentInsets : UIEdgeInsetsMake(buttonMargins, buttonMargins, buttonMargins, buttonMargins))
    }
    
    var linkButtonStyle: ButtonStyle {
        let textStyle = OEXTextStyle(weight: .Normal, size: .Small, color: self.primaryBaseColor())
        return ButtonStyle(textStyle: textStyle, backgroundColor: nil)
    }
    
    var filledEmphasisButtonStyle : ButtonStyle {
        let buttonMargins : CGFloat = 12
        let result = filledPrimaryButtonStyle
        result.backgroundColor = OEXStyles.sharedStyles().utilitySuccessBase()
        result.textStyle = result.textStyle.withSize(.XLarge)
        result.contentInsets = UIEdgeInsetsMake(buttonMargins, buttonMargins, buttonMargins, buttonMargins)
        return result
    }
    
// Standard border styles
    var entryFieldBorderStyle : BorderStyle {
        return BorderStyle(width: .Size(1), color: OEXStyles.sharedStyles().neutralLight())
    }
    
//Standard Divider styles
    
    var standardDividerColor : UIColor {
        return self.neutralLight()
    }
}

extension UIView {
    func applyStandardContainerViewStyle() {
        backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        layer.cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        layer.masksToBounds = true
    }
    
    func applyStandardContainerViewShadow() {
        layer.shadowColor = OEXStyles.sharedStyles().neutralBlack().CGColor;
        layer.shadowRadius = 1.0;
        layer.shadowOffset = CGSizeMake(1, 1);
        layer.shadowOpacity = 0.8;
    }
}

//Standard Search Bar styles
extension UISearchBar {
    func applyStandardStyles(withPlaceholder placeholder : String? = nil) {
        self.placeholder = placeholder
        self.showsCancelButton = false
        self.searchBarStyle = .Default
        self.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        
    }
}

//Convenience computed properties for margins
var StandardHorizontalMargin : CGFloat {
    return OEXStyles.sharedStyles().standardHorizontalMargin()
}

var StandardVerticalMargin : CGFloat {
    return OEXStyles.sharedStyles().standardVerticalMargin
}
