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
    case InternetError
    case UnknownError
    
    case CourseHTMLContent
    case CourseProblemContent
    case CourseUnknownContent
    case CourseVideoContent
    case ContentDownload
    case CourseModeFull
    case CourseModeVideo
    case Transcript
    case OpenURL

    
    private var awesomeRepresentation : FontAwesome {
        switch self {
        case Transcript:
            return .FileTextO
        case .InternetError:
            return .Wifi
        case .UnknownError:
            return .ExclamationCircle
        case .CourseHTMLContent:
            return .FileO
        case .CourseProblemContent:
            return .ThList
        case .CourseUnknownContent:
            return .Laptop
        case .CourseVideoContent:
            return .Film
        case .ContentDownload:
            return .ArrowDown
        case .CourseModeFull:
            return .List
        case .CourseModeVideo:
            return .Film
        case .OpenURL:
            return .ShareSquareO
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
        return fontWithSize(15)
    }
}
