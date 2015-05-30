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
enum Icon {
    case Comment
    case Comments
    case Question
    case CheckSquareO
    case Glass
    case Sort
    case Male
    case Transcript
    case InternetError
    case UnknownError
    case CourseHTMLContent
    case CourseProblemContent
    case CourseUnknownContent
    case CourseVideoContent
    case ContentDownload
    case ReportFlag
    case UpVote
    case FollowStar
    
    private var awesomeRepresentation : FontAwesome {
        switch self {
        case .Comment:
            return .Comment
        case .Comments:
            return .Comments
        case .Question:
            return .Question
        case .CheckSquareO:
            return .CheckSquareO
        case .Glass:
            return .Glass
        case .Sort:
            return .Sort
        case .Male:
            return .Male
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
        case .ReportFlag:
            return .Flag
        case .UpVote:
            return .Plus
        case .FollowStar:
            return .Star
        }
    }
    
    var textRepresentation : String {
        return awesomeRepresentation.rawValue
    }
    
    static func fontWithSize(size : CGFloat) -> UIFont {
        return UIFont.fontAwesomeOfSize(size)
    }
}
