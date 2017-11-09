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
    func drawWithAttributes(attributes : [String : AnyObject], inContext context : CGContext)
}

class FontAwesomeRenderer : IconRenderer {
    let icon : FontAwesome
    
    init(icon : FontAwesome) {
        self.icon = icon
    }
    
    func boundsWithAttributes(attributes : [String : AnyObject], inline : Bool) -> CGRect {
        let string = NSAttributedString(string: icon.rawValue, attributes : attributes)
        let drawingOptions = inline ? NSStringDrawingOptions() : .usesLineFragmentOrigin
        
        return string.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: drawingOptions, context: nil).integral
    }
    
    func drawWithAttributes(attributes : [String : AnyObject], inContext context: CGContext) {
        let string = NSAttributedString(string: icon.rawValue, attributes : attributes)
        let bounds  = boundsWithAttributes(attributes: attributes, inline : false)
        
        string.draw(with: bounds, options: .usesLineFragmentOrigin, context: nil)
    }
    
    var shouldFlip : Bool {
        switch UIApplication.shared.userInterfaceLayoutDirection {
        case .leftToRight:
            return false
        case .rightToLeft:
            // Go through the font awesome representation since those don't change even if the
            // icon's image change and we may use the same icon with different meanings.

            switch icon {
            case .Check, .CheckSquareO, .InfoCircle, .PlayCircleO:
                return false
            default:
                return true
            }
        }
    }
    
}

private class RotatedIconRenderer : IconRenderer {

    private let backing : IconRenderer
    
    init(backing : IconRenderer) {
        self.backing = backing
    }
    
    fileprivate func boundsWithAttributes(attributes: [String : AnyObject], inline: Bool) -> CGRect {
        let bounds = backing.boundsWithAttributes(attributes: attributes, inline: inline)
        // Swap width + height
        return CGRect(x: bounds.minX, y: bounds.minY, width: bounds.height, height: bounds.width)
    }
    
    func drawWithAttributes(attributes : [String : AnyObject], inContext context : CGContext) {
        let bounds = self.boundsWithAttributes(attributes: attributes, inline: false)
        // Draw rotated
        context.translateBy(x: -bounds.midX, y: -bounds.midY)
        context.scaleBy(x: 1.0, y: -1.0);
        context.rotate(by: CGFloat(-Double.pi/2));
        context.translateBy(x: bounds.midY, y: bounds.midX)
        backing.drawWithAttributes(attributes: attributes, inContext: context)
    }
    
    var shouldFlip : Bool {
        return backing.shouldFlip
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
    case Close
    case CircleO
    case CheckCircleO
    case Closed
    case Comment
    case Comments
    case Country
    case Courseware
    case ContentCanDownload
    case ContentDidDownload
    case CourseEffort
    case CourseEnd
    case CourseHTMLContent
    case CourseModeFull
    case CourseVideos
    case CourseProblemContent
    case CourseUnknownContent
    case CourseVideoContent
    case CourseVideoPlay
    case Create
    case Calendar
    case Discussions
    case Dropdown
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
    case RotateDevice
    case Question
    case ReportFlag
    case Settings
    case Sort
    case Spinner
    case StarEmpty
    case StarFilled
    case Transcript
    case UnknownError
    case UpVote
    case User
    case VideoFullscreen
    case VideoPlay
    case VideoPause
    case VideoRewind
    case VideoShrink
    case Warning
    case DeleteIcon
    case MoreOptionsIcon
    
    private var renderer : IconRenderer {
        switch self {
        case .Sort:
            return RotatedIconRenderer(backing: FontAwesomeRenderer(icon: .Exchange))
        case .RotateDevice:
            return RotatedIconRenderer(backing: FontAwesomeRenderer(icon: .Mobile))
        case .ArrowUp:
            return FontAwesomeRenderer(icon: .LongArrowUp)
        case .ArrowDown:
            return FontAwesomeRenderer(icon: .LongArrowDown)
        case .Camera:
            return FontAwesomeRenderer(icon: .Camera)
        case .Close:
            return FontAwesomeRenderer(icon: .Close)
        case .Comment:
            return FontAwesomeRenderer(icon: .Comment)
        case .Comments:
            return FontAwesomeRenderer(icon: .Comments)
        case .Calendar:
            return FontAwesomeRenderer(icon: .Calendar)
        case .Question:
            return FontAwesomeRenderer(icon: .Question)
        case .Answered:
            return FontAwesomeRenderer(icon: .CheckSquareO)
        case .Filter:
            return FontAwesomeRenderer(icon: .Filter)
        case .User:
            return FontAwesomeRenderer(icon: .User)
        case .Create:
            return FontAwesomeRenderer(icon: .PlusCircle)
        case .Pinned:
            return FontAwesomeRenderer(icon: .ThumbTack)
        case .Transcript:
            return FontAwesomeRenderer(icon: .FileTextO)
        case .DeleteIcon:
            return FontAwesomeRenderer(icon: .Trash)
        case .Announcements:
            return FontAwesomeRenderer(icon: .Bullhorn)
        case .CircleO:
            return FontAwesomeRenderer(icon: .CircleO)
        case .CheckCircleO:
            return FontAwesomeRenderer(icon: .CheckCircleO)
        case .ContentCanDownload:
            return FontAwesomeRenderer(icon: .Download)
        case .ContentDidDownload:
            return FontAwesomeRenderer(icon: .Check)
        case .CourseEffort:
            return FontAwesomeRenderer(icon: .Dashboard)
        case .CourseVideoPlay:
            return FontAwesomeRenderer(icon: .PlayCircleO)
        case .CourseEnd:
            return FontAwesomeRenderer(icon: .ClockO)
        case .CourseHTMLContent:
            return FontAwesomeRenderer(icon: .FileO)
        case .CourseModeFull:
            return FontAwesomeRenderer(icon: .List)
        case .Recent:
            return FontAwesomeRenderer(icon: .ArrowsV)
        case .Country:
            return FontAwesomeRenderer(icon: .MapMarker)
        case .CourseVideos:
            return FontAwesomeRenderer(icon: .Film)
        case .CourseProblemContent:
            return FontAwesomeRenderer(icon: .ThList)
        case .Courseware:
            return FontAwesomeRenderer(icon: .ListAlt)
        case .CourseUnknownContent:
            return FontAwesomeRenderer(icon: .Laptop)
        case .CourseVideoContent:
            return FontAwesomeRenderer(icon: .Film)
        case .Menu:
            return FontAwesomeRenderer(icon: .Bars)
        case .ReportFlag:
            return FontAwesomeRenderer(icon: .Flag)
        case .UpVote:
            return FontAwesomeRenderer(icon: .Plus)
        case .FollowStar:
            return FontAwesomeRenderer(icon: .Star)
        case .Discussions:
            return FontAwesomeRenderer(icon: .CommentsO)
        case .Dropdown:
            return FontAwesomeRenderer(icon: .CaretDown)
        case .Graded:
            return FontAwesomeRenderer(icon: .Edit)
        case .Handouts:
            return FontAwesomeRenderer(icon: .FileTextO)
        case .InternetError:
            return FontAwesomeRenderer(icon: .Wifi)
        case .OpenURL:
            return FontAwesomeRenderer(icon: .ShareSquareO)
        case .Settings:
            return FontAwesomeRenderer(icon: .Cog)
        case .Spinner:
            return FontAwesomeRenderer(icon: .Spinner)
        case .StarEmpty:
            return FontAwesomeRenderer(icon: .StarO)
        case .StarFilled:
            return FontAwesomeRenderer(icon: .Star)
        case .UnknownError:
            return FontAwesomeRenderer(icon: .ExclamationCircle)
        case .NoTopics:
            return FontAwesomeRenderer(icon: .List)
        case .NoSearchResults:
            return FontAwesomeRenderer(icon: .InfoCircle)
        case .VideoFullscreen:
            return FontAwesomeRenderer(icon: .Expand)
        case .VideoPlay:
            return FontAwesomeRenderer(icon: .Play)
        case .VideoPause:
            return FontAwesomeRenderer(icon: .Pause)
        case .VideoRewind:
            return FontAwesomeRenderer(icon: .History)
        case .VideoShrink:
            return FontAwesomeRenderer(icon: .Compress)
        case .Closed:
            return FontAwesomeRenderer(icon: .Lock)
        case .Warning:
            return FontAwesomeRenderer(icon: .Exclamation)
        case .MoreOptionsIcon:
            return FontAwesomeRenderer(icon: .EllipsisH)
        }
    }
    
    
    // Do not make this public, since interacting with Icon text directly makes it difficult to account for Right to Left

    public var accessibilityText : String? {
        switch self {
        case .CourseVideoContent:
            return Strings.accessibilityVideo
        case .CourseHTMLContent:
            return Strings.accessibilityHtml
        case .CourseProblemContent:
            return Strings.accessibilityProblem
        case .CourseUnknownContent:
            return Strings.accessibilityUnknown
        default:
            return nil
        }
    }
    
    private func imageWithStyle(style : OEXTextStyle, sizeOverride : CGFloat? = nil, inline : Bool = false) -> UIImage {
        var attributes = style.attributes
        let textSize = sizeOverride ?? OEXTextStyle.pointSize(for: style.size)
        attributes[NSFontAttributeName] = Icon.fontWithSize(size: textSize)
        
        let bounds = renderer.boundsWithAttributes(attributes: attributes as [String : AnyObject], inline: inline)
        let imageSize = bounds.size
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 0)

        if renderer.shouldFlip {
            let context = UIGraphicsGetCurrentContext()
            context!.translateBy(x: imageSize.width, y: 0)
            context!.scaleBy(x: -1, y: 1)
        }
        
        renderer.drawWithAttributes(attributes: attributes as [String : AnyObject], inContext: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.withRenderingMode(.alwaysTemplate)
    }

    public func attributedTextWithStyle(style : OEXTextStyle, inline : Bool = false) -> NSAttributedString {
        var attributes = style.attributes
        attributes[NSFontAttributeName] = Icon.fontWithSize(size: style.size)
        let bounds = renderer.boundsWithAttributes(attributes: attributes as [String : AnyObject], inline : inline)
        
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        attachment.image = imageWithStyle(style: style).withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        attachment.bounds = bounds
        return NSAttributedString(attachment: attachment)
    }
    
    /// Returns a template mask image at the given size
    public func imageWithFontSize(size : CGFloat) -> UIImage {
        return imageWithStyle(style: OEXTextStyle(weight: .normal, size: .base, color: UIColor.black), sizeOverride:size)
    }
    
    func barButtonImage(deltaFromDefault delta : CGFloat = 0) -> UIImage {
        return imageWithFontSize(size: 18 + delta)
    }
    
    private static func fontWithSize(size : CGFloat) -> UIFont {
        return UIFont.fontAwesomeOfSize(fontSize: size)
    }
    
    private static func fontWithSize(size : OEXTextSize) -> UIFont {
        return fontWithSize(size: OEXTextStyle.pointSize(for: size))
    }
    
    private static func fontWithTitleSize() -> UIFont {
        return fontWithSize(size: 17)
    }
}
