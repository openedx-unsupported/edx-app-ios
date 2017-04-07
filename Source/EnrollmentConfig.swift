//
//  EnrollmentConfig.swift
//  edX
//
//  Created by Akiva Leffert on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

enum EnrollmentType : String {
    case Native = "native"
    case Webview = "webview"
    case None = "none"
}

private enum EnrollmentKeys: String, RawStringExtractable {
    case CourseSearchURL = "COURSE_SEARCH_URL"
    case ExploreSubjectsURL = "EXPLORE_SUBJECTS_URL"
    case CourseInfoURLTemplate = "COURSE_INFO_URL_TEMPLATE"
    case NativeSearchBarEnabled = "SEARCH_BAR_ENABLED"
    case EnrollmentType = "TYPE"
    case Webview = "WEBVIEW"
}

class EnrollmentWebviewConfig : NSObject {
    let searchURL: NSURL?
    let exploreSubjectsURL: NSURL?
    let courseInfoURLTemplate: String?
    let nativeSearchbarEnabled: Bool
    
    init(dictionary: [String: AnyObject]) {
        searchURL = (dictionary[EnrollmentKeys.CourseSearchURL] as? String).flatMap { NSURL(string:$0)}
        courseInfoURLTemplate = dictionary[EnrollmentKeys.CourseInfoURLTemplate] as? String
        nativeSearchbarEnabled = dictionary[EnrollmentKeys.NativeSearchBarEnabled] as? Bool ?? false
        exploreSubjectsURL = (dictionary[EnrollmentKeys.ExploreSubjectsURL] as? String).flatMap { NSURL(string:$0)}
    }
}

class EnrollmentConfig : NSObject {
    let type: EnrollmentType
    let webviewConfig: EnrollmentWebviewConfig
    
    init(dictionary: [String: AnyObject]) {
        self.type = (dictionary[EnrollmentKeys.EnrollmentType] as? String).flatMap { EnrollmentType(rawValue: $0) } ?? .None
        self.webviewConfig = EnrollmentWebviewConfig(dictionary: dictionary[EnrollmentKeys.Webview] as? [String: AnyObject] ?? [:])
    }
    
    @discardableResult func isCourseDiscoveryEnabled()-> Bool {
        return self.type != .None
    }
}

private let key = "COURSE_ENROLLMENT"
extension OEXConfig {
    var courseEnrollmentConfig : EnrollmentConfig {
        return EnrollmentConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
