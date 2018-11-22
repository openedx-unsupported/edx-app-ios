//
//  EnrollmentConfig.swift
//  edX
//
//  Created by Akiva Leffert on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

enum EnrollmentType: String {
    case Native = "native"
    case Webview = "webview"
    case None = "none"
}

enum EnrollmentKeys: String, RawStringExtractable {
    case EnrollmentType = "TYPE"
    case Webview = "WEBVIEW"
    case CourseSearchURL = "SEARCH_URL"
    case DetailTemplate = "DETAIL_TEMPLATE"
    case SearchBarEnabled = "SEARCH_BAR_ENABLED"
    case Course = "COURSE_ENROLLMENT"
    case SubjectDiscoveryEnabled = "SUBJECT_DISCOVERY_ENABLED"
    case ExploreSubjectsURL = "EXPLORE_SUBJECTS_URL"
    case Program = "PROGRAM_ENROLLMENT"
}

class EnrollmentWebviewConfig: NSObject {
    let searchURL: NSURL?
    let exploreSubjectsURL: NSURL?
    let detailTemplate: String?
    let searchbarEnabled: Bool
    let subjectDiscoveryEnabled: Bool
    
    init(dictionary: [String: AnyObject]) {
        searchURL = (dictionary[EnrollmentKeys.CourseSearchURL] as? String).flatMap { NSURL(string:$0)}
        detailTemplate = dictionary[EnrollmentKeys.DetailTemplate] as? String
        searchbarEnabled = dictionary[EnrollmentKeys.SearchBarEnabled] as? Bool ?? false
        subjectDiscoveryEnabled = dictionary[EnrollmentKeys.SubjectDiscoveryEnabled] as? Bool ?? false
        exploreSubjectsURL = (dictionary[EnrollmentKeys.ExploreSubjectsURL] as? String).flatMap { NSURL(string:$0)}
    }
}

class EnrollmentConfig: NSObject {
    private(set) var type: EnrollmentType
    let webview: EnrollmentWebviewConfig
        
    var isCourseDiscoveryEnabled: Bool {
        return type != .None
    }
    
    var isProgramDiscoveryEnabled: Bool {
        return type == .Webview
    }
    
    init(dictionary: [String: AnyObject]) {
        type = (dictionary[EnrollmentKeys.EnrollmentType] as? String).flatMap { EnrollmentType(rawValue: $0) } ?? .None
        webview = EnrollmentWebviewConfig(dictionary: dictionary[EnrollmentKeys.Webview] as? [String: AnyObject] ?? [:])
    }
    
    // Associated swift enums can not be used in objective-c, that's why this extra function needed
    func isCourseDiscoveryNative() -> Bool {
        return type == .Native
    }
}

extension OEXConfig {
    
    var programEnrollment: EnrollmentConfig {
        return EnrollmentConfig(dictionary: self[EnrollmentKeys.Program.rawValue] as? [String:AnyObject] ?? [:])
    }
    
    var courseEnrollmentConfig: EnrollmentConfig {
        return EnrollmentConfig(dictionary: self[EnrollmentKeys.Course.rawValue] as? [String:AnyObject] ?? [:])
    }
}
