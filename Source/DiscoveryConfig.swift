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
    case courseDetailTemplate = "COURSE_DETAIL_TEMPLATE"
    case programDetailTemplate = "PROGRAM_DETAIL_TEMPLATE"
}

@objc class DiscoveryWebviewConfig: NSObject {
    @objc let baseURL: URL?
    @objc let courseDetailTemplate: String?
    @objc let programDetailTemplate: String?
    
    init(dictionary: [String: AnyObject]) {
        baseURL = (dictionary[DiscoveryKeys.baseURL] as? String).flatMap { URL(string:$0)}
        courseDetailTemplate = dictionary[DiscoveryKeys.courseDetailTemplate] as? String
        programDetailTemplate = dictionary[DiscoveryKeys.programDetailTemplate] as? String
    }
}

class DiscoveryConfig: NSObject {
    private(set) var type: DiscoveryConfigType
    @objc let webview: DiscoveryWebviewConfig

    init(dictionary: [String: AnyObject]) {
        type = (dictionary[DiscoveryKeys.discoveryType] as? String).flatMap { DiscoveryConfigType(rawValue: $0) } ?? .none
        webview = DiscoveryWebviewConfig(dictionary: dictionary[DiscoveryKeys.webview] as? [String: AnyObject] ?? [:])
    }

    // Associated swift enums can not be used in objective-c, that's why this extra computed property needed
    @objc var isNativeDiscovery: Bool {
        return type == .native
    }

    @objc var isEnabled: Bool {
        return type != .none
    }

}


extension OEXConfig {
    @objc var discovery: DiscoveryConfig {
        return DiscoveryConfig(dictionary: self.properties[DiscoveryKeys.discovery.rawValue] as? [String:AnyObject] ?? [:])
    }
}
