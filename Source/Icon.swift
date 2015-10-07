//
//  Icon.swift
//  edX
//
//  Created by Akiva Leffert on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol IconRenderer : class {
    var shouldFlip : Bool { get }
    func boundsWithAttributes(attributes : [String : AnyObject], inline : Bool) -> CGRect
    func drawWithAttributes(attributes : [String : AnyObject], inContext context : CGContextRef)
}

class FontAwesomeRenderer : IconRenderer {
    let icon : Icon
    init(icon : Icon) {
        self.icon = icon
    }
    
    private var character : FontAwesome {
        switch icon {
        case .ArrowUp:
            return .LongArrowUp
        case .ArrowDown:
            return .LongArrowDown
        case .Camera:
            return .Camera
        case .Comment:
            return .Comment
        case .Comments:
            return .Comments
        case .Question:
            return .Question
        case .Answered:
            return .CheckSquareO
        case .Filter:
            return .Filter
        case .Sort:
            return .Sort
        case .User:
            return .User
        case .Create:
            return .PlusCircle
        case .Pinned:
            return .ThumbTack
        case .Transcript:
            return .FileTextO
        case .Announcements:
            return .Bullhorn
        case .CircleO:
            return .CircleO
        case .CheckCircleO:
            return .CheckCircleO
        case .ContentCanDownload:
            return .ArrowDown
        case .ContentDidDownload:
            return FontAwesome.Check
        case .CourseHTMLContent:
            return .FileO
        case .CourseModeFull:
            return .List
        case .Recent:
            return .ArrowsV
        case .Country:
            return .MapMarker
        case .CourseModeVideo:
            return .Film
        case .CourseProblemContent:
            return .ThList
        case .Courseware:
            return .ListAlt
        case .CourseUnknownContent:
            return .Laptop
        case .CourseVideoContent:
            return .Film
        case .Exclaimation:
            return .Exclamation
        case .Menu:
            return .Bars
        case .Mobile:
            return .Mobile
        case .ReportFlag:
            return .Flag
        case .UpVote:
            return .Plus
        case .FollowStar:
            return .Star
        case .Discussions:
            return .CommentsO
        case .Dropdown:
            return .CaretDown
        case .Graded:
            return .Check
        case .Handouts:
            return .FileTextO
        case .InternetError:
            return .Wifi
        case .OpenURL:
            return .ShareSquareO
        case .ProfileEdit:
            return .Pencil
        case .Settings:
            return .Cog
        case .Spinner:
            return .Spinner
        case .UnknownError:
            return .ExclamationCircle
        case .NoTopics:
            return .List
        case .NoSearchResults:
            return .InfoCircle
        case .VideoFullscreen:
            return .Expand
        case .VideoPlay:
            return .Play
        case .VideoPause:
            return .Pause
        case .VideoRewind:
            return .History
        case .VideoShrink:
            return .Compress
        case .Closed:
            return .Lock
        }
    }
    
    func boundsWithAttributes(attributes : [String : AnyObject], inline : Bool) -> CGRect {
        let string = NSAttributedString(string: character.rawValue, attributes : attributes)
        let drawingOptions = inline ? NSStringDrawingOptions() : .UsesLineFragmentOrigin
        
        return CGRectIntegral(string.boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: drawingOptions, context: nil))
    }
    
    func drawWithAttributes(attributes : [String : AnyObject], inContext context: CGContextRef) {
        let string = NSAttributedString(string: character.rawValue, attributes : attributes)
        let bounds  = boundsWithAttributes(attributes, inline : false)
        
        string.drawWithRect(bounds, options: .UsesLineFragmentOrigin, context: nil)
    }
    
    var shouldFlip : Bool {
        switch UIApplication.sharedApplication().userInterfaceLayoutDirection {
        case .LeftToRight:
            return false
        case .RightToLeft:
            // Go through the font awesome representation since those don't change even if the
            // icon's image change and we may use the same icon with different meanings.

            switch self.character {
            case .Check, .CheckSquareO, .InfoCircle:
                return false
            default:
                return true
            }
        }
    }
    
}

class SortIconRenderer : IconRenderer {
    let sortIcon = FontAwesome.Exchange

    func boundsWithAttributes(attributes : [String : AnyObject], inline : Bool) -> CGRect {
        let string = NSAttributedString(string: sortIcon.rawValue, attributes : attributes)
        let drawingOptions = inline ? NSStringDrawingOptions() : .UsesLineFragmentOrigin
        return string.boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: drawingOptions, context: nil)
    }
    
    func drawWithAttributes(attributes : [String : AnyObject], inContext context : CGContextRef) {
        let string = NSAttributedString(string: sortIcon.rawValue, attributes: attributes)
        let bounds = boundsWithAttributes(attributes, inline : false)
        
        rotateByNinetyDegreesWithBounds(bounds, context: context)
        
        string.drawWithRect(bounds, options: .UsesLineFragmentOrigin, context: nil)
    }
    
    private func rotateByNinetyDegreesWithBounds(bounds : CGRect, context : CGContextRef) {
        CGContextTranslateCTM(context, bounds.size.width / 2, bounds.size.height / 2)
        CGContextRotateCTM(context, CGFloat(90 * M_PI / 180))
        CGContextTranslateCTM(context, bounds.size.width / -2, bounds.size.height / -2)
    }
    
    var shouldFlip : Bool {
        return UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft
    }

}

// Abstracts out FontAwesome so that we can swap it out if necessary
// And also give some of our icons more semantics names
public enum Icon {
    case Answered
    case Announcements
    case ArrowUp
    case ArrowDown
    case Camera
    case CircleO
    case CheckCircleO
    case Closed
    case Comment
    case Comments
    case Country
    case Courseware
    case ContentCanDownload
    case ContentDidDownload
    case CourseHTMLContent
    case CourseModeFull
    case CourseModeVideo
    case CourseProblemContent
    case CourseUnknownContent
    case CourseVideoContent
    case Create
    case Discussions
    case Dropdown
    case Exclaimation
    case Filter
    case Recent
    case FollowStar
    case Graded
    case Handouts
    case InternetError
    case Menu
    case NoTopics
    case NoSearchResults
    case OpenURL
    case Pinned
    case ProfileEdit
    case Mobile
    case Question
    case ReportFlag
    case Settings
    case Sort
    case Spinner
    case Transcript
    case UnknownError
    case UpVote
    case User
    case VideoFullscreen
    case VideoPlay
    case VideoPause
    case VideoRewind
    case VideoShrink
    
    private var renderer : IconRenderer {
        switch self {
        case .Sort:
            return SortIconRenderer()
        default:
            return FontAwesomeRenderer(icon: self)
        }
    }
    
    
    // Do not make this public, since interacting with Icon text directly makes it difficult to account for Right to Left

    public var accessibilityText : String? {
        switch self {
        case .CourseVideoContent:
            return OEXLocalizedString("ACCESSIBILITY_VIDEO", nil)
        case .CourseHTMLContent:
            return OEXLocalizedString("ACCESSIBILITY_HTML", nil)
        case .CourseProblemContent:
            return OEXLocalizedString("ACCESSIBILITY_PROBLEM", nil)
        case .CourseUnknownContent:
            return OEXLocalizedString("ACCESSIBILITY_UNKNOWN", nil)
        default:
            return nil
        }
    }
    
    private func imageWithStyle(style : OEXTextStyle, sizeOverride : CGFloat? = nil, inline : Bool = false) -> UIImage {
        var attributes = style.attributes
        let textSize = sizeOverride ?? OEXTextStyle.pointSizeForTextSize(style.size)
        attributes[NSFontAttributeName] = Icon.fontWithSize(textSize)
        
        let bounds = renderer.boundsWithAttributes(attributes, inline: inline)
        let imageSize = bounds.size
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize.width, imageSize.height), false, 0)

        if renderer.shouldFlip {
            let context = UIGraphicsGetCurrentContext()
            CGContextTranslateCTM(context, imageSize.width, 0)
            CGContextScaleCTM(context, -1, 1)
        }
        
        renderer.drawWithAttributes(attributes, inContext: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image.imageWithRenderingMode(.AlwaysTemplate)
    }

    public func attributedTextWithStyle(style : OEXTextStyle, inline : Bool = false) -> NSAttributedString {
        var attributes = style.attributes
        attributes[NSFontAttributeName] = Icon.fontWithSize(style.size)
        let bounds = renderer.boundsWithAttributes(attributes, inline : inline)
        
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        attachment.image = imageWithStyle(style).imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        attachment.bounds = bounds
        return NSAttributedString(attachment: attachment)
    }
    
    /// Returns a template mask image at the given size
    public func imageWithFontSize(size : CGFloat) -> UIImage {
        return imageWithStyle(OEXTextStyle(weight: .Normal, size: .Base, color: UIColor.blackColor()), sizeOverride:size)
    }
    
    func barButtonImage(deltaFromDefault delta : CGFloat = 0) -> UIImage {
        return imageWithFontSize(18 + delta)
    }
    
    private static func fontWithSize(size : CGFloat) -> UIFont {
        return UIFont.fontAwesomeOfSize(size)
    }
    
    private static func fontWithSize(size : OEXTextSize) -> UIFont {
        return fontWithSize(OEXTextStyle.pointSizeForTextSize(size))
    }
    
    private static func fontWithTitleSize() -> UIFont {
        return fontWithSize(17)
    }
}
