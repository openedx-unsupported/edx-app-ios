//
//  Icon.swift
//  edX
//
//  Created by Akiva Leffert on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol IconRenderer : class {
    var shouldFlip: Bool { get }
    func boundsWithAttributes(attributes: [NSAttributedString.Key : Any], inline : Bool) -> CGRect
    func drawWithAttributes(attributes: [NSAttributedString.Key : Any], inContext context : CGContext)
}

class CustomIconRenderer : IconRenderer {
    let icon: MaterialSharp
    
    init(icon: MaterialSharp) {
        self.icon = icon
    }
    
    func boundsWithAttributes(attributes: [NSAttributedString.Key: Any], inline: Bool) -> CGRect {
        let string = NSAttributedString(string: icon.rawValue, attributes : attributes)
        let drawingOptions = inline ? NSStringDrawingOptions() : .usesLineFragmentOrigin
        
        return string.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: drawingOptions, context: nil).integral
    }
    
    func drawWithAttributes(attributes : [NSAttributedString.Key : Any], inContext context: CGContext) {
        let string = NSAttributedString(string: icon.rawValue, attributes: attributes)
        let bounds  = boundsWithAttributes(attributes: attributes, inline: false)
        
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
            case .check, .checkCircle, .infoOutline, .playCircleFill:
                return false
            default:
                return true
            }
        default:
            return false
        }
    }
}

private class RotatedIconRenderer: IconRenderer {

    private let backing: IconRenderer
    
    init(backing: IconRenderer) {
        self.backing = backing
    }
    
    fileprivate func boundsWithAttributes(attributes: [NSAttributedString.Key: Any], inline: Bool) -> CGRect {
        let bounds = backing.boundsWithAttributes(attributes: attributes, inline: inline)
        // Swap width + height
        return CGRect(x: bounds.minX, y: bounds.minY, width: bounds.height, height: bounds.width)
    }
    
    func drawWithAttributes(attributes: [NSAttributedString.Key : Any], inContext context: CGContext) {
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
    case ChevronRight
    case Close
    case CircleO
    case CheckCircle
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
    case CourseOpenAssesmentContent
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
    case Language
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
    case StarEmpty
    case StarFilled
    case Discovery
    case Transcript
    case Trophy
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
    case Account
    case ArrowLeft
    case Clone
    
    private var renderer : IconRenderer {
        switch self {
        case .Sort:
            return RotatedIconRenderer(backing: CustomIconRenderer(icon: .sort))
        case .RotateDevice:
            return RotatedIconRenderer(backing: CustomIconRenderer(icon: .screenRotation))
        case .ArrowUp:
            return CustomIconRenderer(icon: .arrowUpward)
        case .ArrowDown:
            return CustomIconRenderer(icon: .arrowDownward)
        case .Account:
            return CustomIconRenderer(icon: .moreVert)
        case .Camera:
            return CustomIconRenderer(icon: .cameraAlt)
        case .ChevronRight:
            return CustomIconRenderer(icon: .chevronRight)
        case .Close:
            return CustomIconRenderer(icon: .close)
        case .Clone:
            return CustomIconRenderer(icon: .collectionsBookmark)
        case .Comment:
            return CustomIconRenderer(icon: .comment)
        case .Comments:
            return CustomIconRenderer(icon: .forum)
        case .Calendar:
            return CustomIconRenderer(icon: .event)
        case .Question:
            return CustomIconRenderer(icon: .help)
        case .Answered:
            return CustomIconRenderer(icon: .questionAnswer)
        case .Filter:
            return CustomIconRenderer(icon: .filterAlt)
        case .User:
            return CustomIconRenderer(icon: .person)
        case .Create:
            return CustomIconRenderer(icon: .create)
        case .Pinned:
            return CustomIconRenderer(icon: .pushPin)
        case .Transcript:
            return CustomIconRenderer(icon: .fileCopy)
        case .DeleteIcon:
            return CustomIconRenderer(icon: .delete)
        case .Announcements:
            return CustomIconRenderer(icon: .campaign)
        case .CheckCircle:
            return CustomIconRenderer(icon: .checkCircle)
        case .CircleO:
            return CustomIconRenderer(icon: .addCircle)
        case .CheckCircleO:
            return CustomIconRenderer(icon: .checkCircleOutline)
        case .ContentCanDownload:
            return CustomIconRenderer(icon: .download)
        case .ContentDidDownload:
            return CustomIconRenderer(icon: .downloadDone)
        case .CourseEffort:
            return CustomIconRenderer(icon: .dashboard)
        case .CourseVideoPlay:
            return CustomIconRenderer(icon: .playCircleOutline)
        case .CourseEnd:
            return CustomIconRenderer(icon: .schedule)
        case .CourseHTMLContent:
            return CustomIconRenderer(icon: .article)
        case .CourseOpenAssesmentContent:
            return CustomIconRenderer(icon: .edit)
        case .CourseModeFull:
            return CustomIconRenderer(icon: .list)
        case .Recent:
            return CustomIconRenderer(icon: .recentActors)
        case .Country:
            return CustomIconRenderer(icon: .place)
        case .CourseVideos:
            return CustomIconRenderer(icon: .videocam)
        case .CourseProblemContent:
            return CustomIconRenderer(icon: .summarize)
        case .Courseware:
            return CustomIconRenderer(icon: .classroom)
        case .CourseUnknownContent:
            return CustomIconRenderer(icon: .laptop)
        case .CourseVideoContent:
            return CustomIconRenderer(icon: .videocam)
        case .Menu:
            return CustomIconRenderer(icon: .menu)
        case .ReportFlag:
            return CustomIconRenderer(icon: .flag)
        case .UpVote:
            return CustomIconRenderer(icon: .thumbUp)
        case .FollowStar:
            return CustomIconRenderer(icon: .star)
        case .Discussions:
            return CustomIconRenderer(icon: .forum)
        case .Dropdown:
            return CustomIconRenderer(icon: .arrowDropDown)
        case .Graded:
            return CustomIconRenderer(icon: .factCheck)
        case .Handouts:
            return CustomIconRenderer(icon: .description)
        case .InternetError:
            return CustomIconRenderer(icon: .wifi)
        case .OpenURL:
            return CustomIconRenderer(icon: .openInBrowser)
        case .Settings:
            return CustomIconRenderer(icon: .settings)
        case .StarEmpty:
            return CustomIconRenderer(icon: .starOutline)
        case .StarFilled:
            return CustomIconRenderer(icon: .star)
        case .Discovery:
            return CustomIconRenderer(icon: .search)
        case .UnknownError:
            return CustomIconRenderer(icon: .error)
        case .NoTopics:
            return CustomIconRenderer(icon: .list)
        case .NoSearchResults:
            return CustomIconRenderer(icon: .playCircleOutline)
        case .Trophy:
            return CustomIconRenderer(icon: .emojiEvents)
        case .VideoFullscreen:
            return CustomIconRenderer(icon: .expandMore)
        case .VideoPlay:
            return CustomIconRenderer(icon: .playArrow)
        case .VideoPause:
            return CustomIconRenderer(icon: .pause)
        case .VideoRewind:
            return CustomIconRenderer(icon: .history)
        case .VideoShrink:
            return CustomIconRenderer(icon: .expandLess)
        case .Closed:
            return CustomIconRenderer(icon: .lock)
        case .Warning:
            return CustomIconRenderer(icon: .error)
        case .MoreOptionsIcon:
            return CustomIconRenderer(icon: .moreHoriz)
        case .ArrowLeft:
            return CustomIconRenderer(icon: .keyboardArrowLeft)
        case .Language:
            return CustomIconRenderer(icon: .language)
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
    
    private func imageWithStyle(style: OEXTextStyle, sizeOverride: CGFloat? = nil, inline: Bool = false) -> UIImage {
        var attributes = style.attributes.attributedKeyDictionary()
        let textSize = sizeOverride ?? OEXTextStyle.pointSize(for: style.size)
        attributes[NSAttributedString.Key.font] = Icon.fontWithSize(size: textSize)
        
        let bounds = renderer.boundsWithAttributes(attributes: attributes, inline: inline)
        let imageSize = bounds.size
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 0)

        if renderer.shouldFlip {
            let context = UIGraphicsGetCurrentContext()
            context!.translateBy(x: imageSize.width, y: 0)
            context!.scaleBy(x: -1, y: 1)
        }
        
        renderer.drawWithAttributes(attributes: attributes, inContext: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.withRenderingMode(.alwaysTemplate)
    }

    public func attributedTextWithStyle(style: OEXTextStyle, inline: Bool = false) -> NSAttributedString {
        var attributes = style.attributes.attributedKeyDictionary()
        attributes[NSAttributedString.Key.font] = Icon.fontWithSize(size: style.size)
        let bounds = renderer.boundsWithAttributes(attributes: attributes, inline : inline)
        
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        attachment.image = imageWithStyle(style: style).withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        attachment.bounds = bounds
        return NSAttributedString(attachment: attachment)
    }
    
    /// Returns a template mask image at the given size
    public func imageWithFontSize(size: CGFloat) -> UIImage {
        return imageWithStyle(style: OEXTextStyle(weight: .normal, size: .base, color: UIColor.black), sizeOverride:size)
    }
    
    func barButtonImage(deltaFromDefault delta: CGFloat = 0) -> UIImage {
        return imageWithFontSize(size: 18 + delta)
    }
    
    private static func fontWithSize(size: CGFloat) -> UIFont {
        return UIFont.customIcon(of: size)
    }
    
    private static func fontWithSize(size: OEXTextSize) -> UIFont {
        return fontWithSize(size: OEXTextStyle.pointSize(for: size))
    }
    
    private static func fontWithTitleSize() -> UIFont {
        return fontWithSize(size: 17)
    }
}
