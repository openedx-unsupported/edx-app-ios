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
        return Icon.VideoRewind.imageWithFontSize(size: videoIconSize)
    }
    
    class func ExpandIcon() -> UIImage {
        return Icon.VideoFullscreen.imageWithFontSize(size: videoIconSize)
    }
    
    class func ShrinkIcon() -> UIImage {
        return Icon.VideoShrink.imageWithFontSize(size: videoIconSize)
    }
    
    class func OpenURL() -> UIImage {
        return Icon.OpenURL.imageWithFontSize(size: videoIconSize)
    }
    
    class func PauseIcon() -> UIImage {
        return Icon.VideoPause.imageWithFontSize(size: videoIconSize)
    }

    class func PlayIcon() -> UIImage {
        return Icon.VideoPlay.imageWithFontSize(size: videoIconSize)
    }
    
    class func SettingsIcon() -> UIImage {
        return Icon.Settings.imageWithFontSize(size: videoIconSize)
    }
    
    class func PlayTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxLarge, color: UIColor.white)
        style.alignment = .center
        return Icon.VideoPlay.attributedTextWithStyle(style: style, inline: true)
    }
    
    class func PauseTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle(weight: .normal, size: .xxLarge, color: UIColor.white)
        style.alignment = .center
        return Icon.VideoPause.attributedTextWithStyle(style: style, inline: true)
    }
}
