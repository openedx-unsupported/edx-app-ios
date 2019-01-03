//
//  DiscoveryConfig.swift
//  edX
//
//  Created by Akiva Leffert on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

enum DiscoveryConfigType: String {
    case Native = "native"
    case Webview = "webview"
    case None = "none"
}

enum DiscoveryKeys: String, RawStringExtractable {
    case Discovery = "DISCOVERY"
    case DiscoveryType = "TYPE"
    case Webview = "WEBVIEW"
    case BaseURL = "BASE_URL"
    case DetailTemplate = "DETAIL_TEMPLATE"
    case SearchEnabled = "SEARCH_ENABLED"
    case Course = "COURSE"
    case SubjectDiscoveryEnabled = "SUBJECT_DISCOVERY_ENABLED"
    case ExploreSubjectsURL = "EXPLORE_SUBJECTS_URL"
    case Program = "PROGRAM"
}

class DiscoveryWebviewConfig: NSObject {
    let baseURL: URL?
    let exploreSubjectsURL: URL?
    let detailTemplate: String?
    let searchEnabled: Bool
    let subjectDiscoveryEnabled: Bool
    
    init(dictionary: [String: AnyObject]) {
        baseURL = (dictionary[DiscoveryKeys.BaseURL] as? String).flatMap { URL(string:$0)}
        detailTemplate = dictionary[DiscoveryKeys.DetailTemplate] as? String
        searchEnabled = dictionary[DiscoveryKeys.SearchEnabled] as? Bool ?? false
        subjectDiscoveryEnabled = dictionary[DiscoveryKeys.SubjectDiscoveryEnabled] as? Bool ?? false
        exploreSubjectsURL = (dictionary[DiscoveryKeys.ExploreSubjectsURL] as? String).flatMap { URL(string:$0)}
    }
}

class DiscoveryConfig: NSObject {
    let course: CourseDiscovery
    let program: ProgramDiscovery
    
    init(dictionary: [String: AnyObject]) {
        course = CourseDiscovery(dictionary: dictionary[DiscoveryKeys.Course] as? [String: AnyObject] ?? [:])
        program = ProgramDiscovery(with: course, dictionary: dictionary[DiscoveryKeys.Program] as? [String: AnyObject] ?? [:])
    }
}

class CourseDiscovery: DiscoveryBase {
    
    var isEnabled: Bool {
        return type != .None
    }
    
    // Associated swift enums can not be used in objective-c, that's why this extra computed property needed
    var isCourseDiscoveryNative: Bool {
        return type == .Native
    }
}

class ProgramDiscovery: DiscoveryBase {
    
    private let courseDiscovery: CourseDiscovery
    
    init(with courseDiscovery: CourseDiscovery, dictionary: [String : AnyObject]) {
        self.courseDiscovery = courseDiscovery
        super.init(dictionary: dictionary)
    }
    
    var isEnabled: Bool {
        return courseDiscovery.type == .Webview && type == .Webview
    }
}

class DiscoveryBase: NSObject {
    private(set) var type: DiscoveryConfigType
    let webview: DiscoveryWebviewConfig
    
    init(dictionary: [String: AnyObject]) {
        type = (dictionary[DiscoveryKeys.DiscoveryType] as? String).flatMap { DiscoveryConfigType(rawValue: $0) } ?? .None
        webview = DiscoveryWebviewConfig(dictionary: dictionary[DiscoveryKeys.Webview] as? [String: AnyObject] ?? [:])
    }
}

extension OEXConfig {
    
    var discovery: DiscoveryConfig {
        return DiscoveryConfig(dictionary: self[DiscoveryKeys.Discovery.rawValue] as? [String:AnyObject] ?? [:])
    }
}
