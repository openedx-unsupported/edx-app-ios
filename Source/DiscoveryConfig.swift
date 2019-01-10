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
    case native = "native"
    case webview = "webview"
    case none = "none"
}

enum DiscoveryKeys: String, RawStringExtractable {
    case discovery = "DISCOVERY"
    case discoveryType = "TYPE"
    case webview = "WEBVIEW"
    case baseURL = "BASE_URL"
    case detailTemplate = "DETAIL_TEMPLATE"
    case searchEnabled = "SEARCH_ENABLED"
    case course = "COURSE"
    case subjectFilterEnabled = "SUBJECT_FILTER_ENABLED"
    case exploreSubjectsURL = "EXPLORE_SUBJECTS_URL"
    case program = "PROGRAM"
}

class DiscoveryWebviewConfig: NSObject {
    let baseURL: URL?
    let exploreSubjectsURL: URL?
    let detailTemplate: String?
    let searchEnabled: Bool
    let subjectFilterEnabled: Bool
    
    init(dictionary: [String: AnyObject]) {
        baseURL = (dictionary[DiscoveryKeys.baseURL] as? String).flatMap { URL(string:$0)}
        detailTemplate = dictionary[DiscoveryKeys.detailTemplate] as? String
        searchEnabled = dictionary[DiscoveryKeys.searchEnabled] as? Bool ?? false
        subjectFilterEnabled = dictionary[DiscoveryKeys.subjectFilterEnabled] as? Bool ?? false
        exploreSubjectsURL = (dictionary[DiscoveryKeys.exploreSubjectsURL] as? String).flatMap { URL(string:$0)}
    }
}

class DiscoveryConfig: NSObject {
    let course: CourseDiscovery
    let program: ProgramDiscovery
    
    init(dictionary: [String: AnyObject]) {
        course = CourseDiscovery(dictionary: dictionary[DiscoveryKeys.course] as? [String: AnyObject] ?? [:])
        program = ProgramDiscovery(with: course, dictionary: dictionary[DiscoveryKeys.program] as? [String: AnyObject] ?? [:])
    }
}

class CourseDiscovery: DiscoveryBase {
    
    var isEnabled: Bool {
        return type != .none
    }
    
    // Associated swift enums can not be used in objective-c, that's why this extra computed property needed
    var isCourseDiscoveryNative: Bool {
        return type == .native
    }
}

class ProgramDiscovery: DiscoveryBase {
    
    private let courseDiscovery: CourseDiscovery
    
    init(with courseDiscovery: CourseDiscovery, dictionary: [String : AnyObject]) {
        self.courseDiscovery = courseDiscovery
        super.init(dictionary: dictionary)
    }
    
    var isEnabled: Bool {
        return courseDiscovery.type == .webview && type == .webview
    }
}

class DiscoveryBase: NSObject {
    private(set) var type: DiscoveryConfigType
    let webview: DiscoveryWebviewConfig
    
    init(dictionary: [String: AnyObject]) {
        type = (dictionary[DiscoveryKeys.discoveryType] as? String).flatMap { DiscoveryConfigType(rawValue: $0) } ?? .none
        webview = DiscoveryWebviewConfig(dictionary: dictionary[DiscoveryKeys.webview] as? [String: AnyObject] ?? [:])
    }
}

extension OEXConfig {
    
    var discovery: DiscoveryConfig {
        return DiscoveryConfig(dictionary: self[DiscoveryKeys.discovery.rawValue] as? [String:AnyObject] ?? [:])
    }
}
