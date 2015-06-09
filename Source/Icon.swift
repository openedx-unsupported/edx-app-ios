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
    case Announcements
    case ContentDownload
    case Courseware
    case CourseHTMLContent
    case CourseModeFull
    case CourseModeVideo
    case CourseProblemContent
    case CourseUnknownContent
    case CourseVideoContent
    case Discussions
    case Dropdown
    case Graded
    case Handouts
    case InternetError
    case OpenURL
    case Spinner
    case Transcript
    case UnknownError
    
    private var awesomeRepresentation : FontAwesome {
        switch self {
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
