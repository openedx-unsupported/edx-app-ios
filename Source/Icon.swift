//
//  Icon.swift
//  edX
//
//  Created by Akiva Leffert on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol IconRenderer {
    var shouldFlip: Bool { get }
    func boundsWithAttributes(attributes: [NSAttributedString.Key : Any], inline : Bool) -> CGRect
    func drawWithAttributes(attributes: [NSAttributedString.Key : Any], inContext context : CGContext)
}

class MaterialIconRenderer : IconRenderer {
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
            // Go through the icon representation since those don't change even if the
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

// Abstracts out Material Sharp so that we can swap it out if necessary
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
    case Check
    case CheckCircle
    case CheckCircleO
    case Closed
    case Comment
    case Comments
    case Country
    case Courseware
    case CoursewareEnrolled
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
    case DoubleArrow
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
    case ShareCourse
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
    case OpenInBrowser
    
    private var renderer : IconRenderer {
        switch self {
        case .Sort:
            return RotatedIconRenderer(backing: MaterialIconRenderer(icon: .sort))
        case .RotateDevice:
            return RotatedIconRenderer(backing: MaterialIconRenderer(icon: .screenRotation))
        case .ArrowUp:
            return MaterialIconRenderer(icon: .arrowUpward)
        case .ArrowDown:
            return MaterialIconRenderer(icon: .arrowDownward)
        case .Account:
            return MaterialIconRenderer(icon: .moreVert)
        case .Camera:
            return MaterialIconRenderer(icon: .cameraAlt)
        case .ChevronRight:
            return MaterialIconRenderer(icon: .chevronRight)
        case .Close:
            return MaterialIconRenderer(icon: .close)
        case .Clone:
            return MaterialIconRenderer(icon: .collectionsBookmark)
        case .Comment:
            return MaterialIconRenderer(icon: .comment)
        case .Comments:
            return MaterialIconRenderer(icon: .forum)
        case .Calendar:
            return MaterialIconRenderer(icon: .event)
        case .Question:
            return MaterialIconRenderer(icon: .help)
        case .Answered:
            return MaterialIconRenderer(icon: .questionAnswer)
        case .Filter:
            return MaterialIconRenderer(icon: .filterAlt)
        case .User:
            return MaterialIconRenderer(icon: .person)
        case .Create:
            return MaterialIconRenderer(icon: .create)
        case .Pinned:
            return MaterialIconRenderer(icon: .pushPin)
        case .Transcript:
            return MaterialIconRenderer(icon: .fileCopy)
        case .DeleteIcon:
            return MaterialIconRenderer(icon: .delete)
        case .Announcements:
            return MaterialIconRenderer(icon: .campaign)
        case .Check:
            return MaterialIconRenderer(icon: .check)
        case .CheckCircle:
            return MaterialIconRenderer(icon: .checkCircle)
        case .CircleO:
            return MaterialIconRenderer(icon: .addCircle)
        case .CheckCircleO:
            return MaterialIconRenderer(icon: .checkCircleOutline)
        case .ContentCanDownload:
            return MaterialIconRenderer(icon: .download)
        case .ContentDidDownload:
            return MaterialIconRenderer(icon: .downloadDone)
        case .CourseEffort:
            return MaterialIconRenderer(icon: .dashboard)
        case .CourseVideoPlay:
            return MaterialIconRenderer(icon: .playCircleOutline)
        case .CourseEnd:
            return MaterialIconRenderer(icon: .schedule)
        case .CourseHTMLContent:
            return MaterialIconRenderer(icon: .article)
        case .CourseOpenAssesmentContent:
            return MaterialIconRenderer(icon: .edit)
        case .CourseModeFull:
            return MaterialIconRenderer(icon: .list)
        case .Recent:
            return MaterialIconRenderer(icon: .recentActors)
        case .Country:
            return MaterialIconRenderer(icon: .place)
        case .CourseVideos:
            return MaterialIconRenderer(icon: .videocam)
        case .CourseProblemContent:
            return MaterialIconRenderer(icon: .summarize)
        case .Courseware:
            return MaterialIconRenderer(icon: .classroom)
        case .CoursewareEnrolled:
            return MaterialIconRenderer(icon: .bookmarkBorder)
        case .CourseUnknownContent:
            return MaterialIconRenderer(icon: .laptop)
        case .CourseVideoContent:
            return MaterialIconRenderer(icon: .videocam)
        case .Menu:
            return MaterialIconRenderer(icon: .menu)
        case .ReportFlag:
            return MaterialIconRenderer(icon: .flag)
        case .UpVote:
            return MaterialIconRenderer(icon: .thumbUp)
        case .FollowStar:
            return MaterialIconRenderer(icon: .star)
        case .Discussions:
            return MaterialIconRenderer(icon: .forum)
        case .Dropdown:
            return MaterialIconRenderer(icon: .arrowDropDown)
        case .DoubleArrow:
            return MaterialIconRenderer(icon: .syncAlt)
        case .Graded:
            return MaterialIconRenderer(icon: .factCheck)
        case .Handouts:
            return MaterialIconRenderer(icon: .description)
        case .InternetError:
            return MaterialIconRenderer(icon: .wifi)
        case .OpenURL:
            return MaterialIconRenderer(icon: .openInBrowser)
        case .Settings:
            return MaterialIconRenderer(icon: .settings)
        case .StarEmpty:
            return MaterialIconRenderer(icon: .starOutline)
        case .StarFilled:
            return MaterialIconRenderer(icon: .star)
        case .ShareCourse:
            return MaterialIconRenderer(icon: .shareiOS)
        case .Discovery:
            return MaterialIconRenderer(icon: .search)
        case .UnknownError:
            return MaterialIconRenderer(icon: .error)
        case .NoTopics:
            return MaterialIconRenderer(icon: .list)
        case .NoSearchResults:
            return MaterialIconRenderer(icon: .playCircleOutline)
        case .Trophy:
            return MaterialIconRenderer(icon: .emojiEvents)
        case .VideoFullscreen:
            return MaterialIconRenderer(icon: .fullscreen)
        case .VideoPlay:
            return MaterialIconRenderer(icon: .playArrow)
        case .VideoPause:
            return MaterialIconRenderer(icon: .pause)
        case .VideoRewind:
            return MaterialIconRenderer(icon: .history)
        case .VideoShrink:
            return MaterialIconRenderer(icon: .fullscreenExit)
        case .Closed:
            return MaterialIconRenderer(icon: .lock)
        case .Warning:
            return MaterialIconRenderer(icon: .error)
        case .MoreOptionsIcon:
            return MaterialIconRenderer(icon: .moreHoriz)
        case .ArrowLeft:
            return MaterialIconRenderer(icon: .keyboardArrowLeft)
        case .Language:
            return MaterialIconRenderer(icon: .language)
        case .OpenInBrowser:
            return MaterialIconRenderer(icon: .openInNew)
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
