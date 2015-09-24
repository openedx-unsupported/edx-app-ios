//
//  UIImage+OEXIcon.swift
//  edX
//
//  Created by Michael Katz on 8/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

let videoIconSize: CGFloat = 32.0


extension UIImage { //OEXIcon
    class func MenuIcon() -> UIImage {
        return Icon.Menu.barButtonImage(deltaFromDefault: 0)
    }
    
    class func RewindIcon() -> UIImage {
        return Icon.VideoRewind.imageWithFontSize(videoIconSize)
    }
    
    class func ExpandIcon() -> UIImage {
        return Icon.VideoFullscreen.imageWithFontSize(videoIconSize)
    }
    
    class func ShrinkIcon() -> UIImage {
        return Icon.VideoShrink.imageWithFontSize(videoIconSize)
    }
    
    class func OpenURL() -> UIImage {
        return Icon.OpenURL.imageWithFontSize(videoIconSize)
    }
    
    class func PauseIcon() -> UIImage {
        return Icon.VideoPause.imageWithFontSize(videoIconSize)
    }

    class func PlayIcon() -> UIImage {
        return Icon.VideoPlay.imageWithFontSize(videoIconSize)
    }
    
    class func SettingsIcon() -> UIImage {
        return Icon.Settings.imageWithFontSize(videoIconSize)
    }
    
    class func PlayTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle(weight: .Normal, size: .XXLarge, color: UIColor.whiteColor())
        style.alignment = .Center
        return Icon.VideoPlay.attributedTextWithStyle(style, inline: true)
    }
    
    class func PauseTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle(weight: .Normal, size: .XXLarge, color: UIColor.whiteColor())
        style.alignment = .Center
        return Icon.VideoPause.attributedTextWithStyle(style, inline: true)
    }
}