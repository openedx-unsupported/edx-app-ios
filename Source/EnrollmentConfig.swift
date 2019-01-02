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
    case Enrollment = "ENROLLMENT"
    case EnrollmentType = "TYPE"
    case Webview = "WEBVIEW"
    case CourseSearchURL = "SEARCH_URL"
    case DetailTemplate = "DETAIL_TEMPLATE"
    case SearchBarEnabled = "SEARCH_BAR_ENABLED"
    case Course = "COURSE"
    case SubjectDiscoveryEnabled = "SUBJECT_DISCOVERY_ENABLED"
    case ExploreSubjectsURL = "EXPLORE_SUBJECTS_URL"
    case Program = "PROGRAM"
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
    let course: CourseEnrollment
    let program: ProgramEnrollment
    
    init(dictionary: [String: AnyObject]) {
        course = CourseEnrollment(dictionary: dictionary[EnrollmentKeys.Course] as? [String: AnyObject] ?? [:])
        program = ProgramEnrollment(with: course, dictionary: dictionary[EnrollmentKeys.Program] as? [String: AnyObject] ?? [:])
    }
}

class CourseEnrollment: Enrollment {
    
    var isEnabled: Bool {
        return type != .None
    }
    
    // Associated swift enums can not be used in objective-c, that's why this extra computed property needed
    var isCourseDiscoveryNative: Bool {
        return type == .Native
    }
}

class ProgramEnrollment: Enrollment {
    
    private let courseEnrollment: CourseEnrollment
    
    init(with courseEnrollment: CourseEnrollment, dictionary: [String : AnyObject]) {
        self.courseEnrollment = courseEnrollment
        super.init(dictionary: dictionary)
    }
    
    var isEnabled: Bool {
        return courseEnrollment.type == .Webview && type == .Webview
    }
}

class Enrollment: NSObject {
    private(set) var type: EnrollmentType
    let webview: EnrollmentWebviewConfig
    
    init(dictionary: [String: AnyObject]) {
        type = (dictionary[EnrollmentKeys.EnrollmentType] as? String).flatMap { EnrollmentType(rawValue: $0) } ?? .None
        webview = EnrollmentWebviewConfig(dictionary: dictionary[EnrollmentKeys.Webview] as? [String: AnyObject] ?? [:])
    }
}

extension OEXConfig {
    
    var enrollment: EnrollmentConfig {
        return EnrollmentConfig(dictionary: self[EnrollmentKeys.Enrollment.rawValue] as? [String:AnyObject] ?? [:])
    }
}
