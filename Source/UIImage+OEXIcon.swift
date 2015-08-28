//
//  UIImage+OEXIcon.swift
//  edX
//
//  Created by Michael Katz on 8/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

let videoIconSize: CGFloat = 32.0
//let videoPlayGlyphSize: CGFloat = 32.0
//let videoPortraitPlayGlyphSize: CGFloat = 60.0
//let videoLandscapePlayGlyphSize: CGFloat = 76.0
//let videoPortraitPlaySize: CGFloat = 96.0
//let videoLandscapePlaySize: CGFloat = 120.0


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
    
//    class func PauseIconLandscape() -> UIImage {
//        return Icon.VideoPause.imageWithCircleBackground(videoLandscapePlaySize, glyphSize: videoLandscapePlayGlyphSize)
//    }
//
//    class func PlayIconLandscape() -> UIImage {
//        return Icon.VideoPlay.imageWithCircleBackground(videoLandscapePlaySize, glyphSize: videoLandscapePlayGlyphSize)
//    }
//
//    class func PauseIconPortrait() -> UIImage {
//        return Icon.VideoPause.imageWithCircleBackground(videoPortraitPlaySize, glyphSize: videoPortraitPlayGlyphSize)
//    }
//
//    class func PlayIconPortrait() -> UIImage {
//        return Icon.VideoPlay.imageWithCircleBackground(videoPortraitPlaySize, glyphSize: videoPortraitPlayGlyphSize)
//    }
    
    class func PlayTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle()
        style.alignment = .Center
        style.color = UIColor.whiteColor()
        style.size = .XXLarge
        return Icon.VideoPlay.attributedTextWithStyle(style, inline: true)
    }
    
    class func PauseTitle() -> NSAttributedString {
        let style = OEXMutableTextStyle()
        style.alignment = .Center
        style.color = UIColor.whiteColor()
        style.size = .XXLarge
        return Icon.VideoPause.attributedTextWithStyle(style, inline: true)
    }
}