//
//  Icon.swift
//  edX
//
//  Created by Akiva Leffert on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


// Abstracts out FontAwesome so that we can swap it out if necessary
// And also give some of our icons more semantics names
public enum Icon {
    case Answered
    case Announcements
    case Comment
    case Comments
    case Courseware
    case ContentDownload
    case CourseHTMLContent
    case CourseModeFull
    case CourseModeVideo
    case CourseProblemContent
    case CourseUnknownContent
    case CourseVideoContent
    case Create
    case Discussions
    case Dropdown
    case Filter
    case Recent
    case FollowStar
    case Graded
    case Handouts
    case InternetError
    case OpenURL
    case Pinned
    case Mobile
    case Question
    case ReportFlag
    case Sort
    case Spinner
    case Transcript
    case UnknownError
    case UpVote
    case User
    
    private var awesomeRepresentation : FontAwesome {
        switch self {
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
        case Transcript:
            return .FileTextO
        case .Announcements:
            return .Bullhorn
        case .ContentDownload:
            return .ArrowDown
        case .CourseHTMLContent:
            return .FileO
        case .CourseModeFull:
            return .List
        case .Recent:
            return .ArrowsV
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
        case .ContentDownload:
            return .ArrowDown
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
        case .Spinner:
            return .Spinner
        case Transcript:
            return .FileTextO
        case .UnknownError:
            return .ExclamationCircle
        }
    }
    
    // Do not make this public, since interacting with Icon text directly makes it difficult to account for Right to Left
    private var textRepresentation : String {
        return awesomeRepresentation.rawValue
    }
    
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
    
    private var shouldFlip : Bool {
        switch UIApplication.sharedApplication().userInterfaceLayoutDirection {
        case .LeftToRight:
            return false
        case .RightToLeft:
            // Go through the font awesome representation since those don't change even if the 
            // icon's image change and we may use the same icon with different meanings.
            switch self.awesomeRepresentation {
            case .Check, .CheckSquareO:
                return false
            default:
                return true
            }
        }
    }
    
    private func imageWithStyle(style : OEXTextStyle, sizeOverride : CGFloat? = nil) -> UIImage {
        var attributes = style.attributes
        let textSize = sizeOverride ?? OEXTextStyle.pointSizeForTextSize(style.size)
        attributes[NSFontAttributeName] = Icon.fontWithSize(textSize)
        let string = NSAttributedString(string: textRepresentation, attributes : attributes)
        let bounds = CGRectIntegral(string.boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: .UsesLineFragmentOrigin, context: nil))
        let imageSize = bounds.size
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize.width, imageSize.height), false, 0)
        if shouldFlip {
            let context = UIGraphicsGetCurrentContext()
            CGContextTranslateCTM(context, imageSize.width, 0)
            CGContextScaleCTM(context, -1, 1)
        }
        string.drawWithRect(bounds, options: .UsesLineFragmentOrigin, context: nil)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image.imageWithRenderingMode(.AlwaysTemplate)
    }
    
    public func attributedTextWithStyle(style : OEXTextStyle) -> NSAttributedString {
        var attributes = style.attributes
        attributes[NSFontAttributeName] = Icon.fontWithSize(style.size)
        let string = NSAttributedString(string: textRepresentation, attributes : attributes)
        let bounds = string.boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: NSStringDrawingOptions(), context: nil)
        
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        attachment.image = imageWithStyle(style).imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        attachment.bounds = bounds
        return NSAttributedString(attachment: attachment)
    }
    
    /// Returns a template mask image at the given size
    public func imageWithFontSize(size : CGFloat) -> UIImage {
        return imageWithStyle(OEXTextStyle().withColor(UIColor.blackColor()), sizeOverride : size)
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
