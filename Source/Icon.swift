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
    case FollowStar
    case Graded
    case Handouts
    case InternetError
    case OpenURL
    case Pinned
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
            return .Glass
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
            return .FileTextO
        case .ContentDownload:
            return .ArrowDown
        case .CourseHTMLContent:
            return .FileO
        case .CourseModeFull:
            return .List
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
            return .Bullhorn
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
    
    var textRepresentation : String {
        return awesomeRepresentation.rawValue
    }
    
    func attributedTextWithSize(size : CGFloat) -> NSAttributedString {
        return NSAttributedString(string: textRepresentation, attributes: [NSFontAttributeName : Icon.fontWithSize(size)])
    }
    
    static func fontWithSize(size : CGFloat) -> UIFont {
        return UIFont.fontAwesomeOfSize(size)
    }
    
    static func fontWithTitleSize() -> UIFont {
        return fontWithSize(17)
    }
}
