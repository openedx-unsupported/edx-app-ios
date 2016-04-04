//
//  EnrollmentConfig.swift
//  edX
//
//  Created by Akiva Leffert on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

enum EnrollmentType : String {
    case Native = "native"
    case Webview = "webview"
}

private enum EnrollmentKeys: String, RawStringExtractable {
    case CourseSearchURL = "COURSE_SEARCH_URL"
    case CourseInfoURLTemplate = "COURSE_INFO_URL_TEMPLATE"
    case NativeSearchBarEnabled = "SEARCH_BAR_ENABLED"
    case EnrollmentType = "TYPE"
    case Webview = "WEBVIEW"
}

class EnrollmentWebviewConfig : NSObject {
    let searchURL: NSURL?
    let courseInfoURLTemplate: String?
    let nativeSeachbarEnabled: Bool
    
    init(dictionary: [String: AnyObject]) {
        searchURL = (dictionary[EnrollmentKeys.CourseSearchURL] as? String).flatMap { NSURL(string:$0)}
        courseInfoURLTemplate = dictionary[EnrollmentKeys.CourseInfoURLTemplate] as? String
        nativeSeachbarEnabled = dictionary[EnrollmentKeys.NativeSearchBarEnabled] as? Bool ?? false
    }
}

class EnrollmentConfig : NSObject {
    let type: EnrollmentType
    let webviewConfig: EnrollmentWebviewConfig
    
    init(dictionary: [String: AnyObject]) {
        self.type = (dictionary[EnrollmentKeys.EnrollmentType] as? String).flatMap { EnrollmentType(rawValue: $0) } ?? .Native
        self.webviewConfig = EnrollmentWebviewConfig(dictionary: dictionary[EnrollmentKeys.Webview] as? [String: AnyObject] ?? [:])
    }
}

private let key = "COURSE_ENROLLMENT"
extension OEXConfig {
    var courseEnrollmentConfig : EnrollmentConfig {
        return EnrollmentConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
