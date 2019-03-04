//
//  DeepLink.swift
//  edX
//
//  Created by Salman on 02/10/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

enum DeepLinkType: String {
    case courseDashboard = "course_dashboard"
    case courseVideos = "course_videos"
    case discussions = "course_discussion"
    case courseDiscovery = "course_discovery"
    case programDiscovery = "program_discovery"
    case programDiscoveryDetail = "program_discovery_detail"
    case courseDetail = "course_detail"
    case program = "program"
    case programDetail = "program_detail"
    case account = "account"
    case profile = "profile"
    case none = "none"
}

fileprivate enum DeepLinkKeys: String, RawStringExtractable {
    case CourseId = "course_id"
    case PathID = "path_id"
    case ScreenName = "screen_name"
}

class DeepLink: NSObject {

    let courseId: String?
    let screenName: String?
    let pathID: String?
    var type: DeepLinkType {
        let type = DeepLinkType(rawValue: screenName ?? DeepLinkType.none.rawValue) ?? .none
        if type == .courseDiscovery && courseId != nil {
            return .courseDetail
        }
        else if type == .programDiscovery && pathID != nil {
            return .programDiscoveryDetail
        }
        else if type == .program && pathID != nil {
            return .programDetail
        }
        return type
    }
    
    init(dictionary:[String:Any]) {
        courseId = dictionary[DeepLinkKeys.CourseId] as? String
        screenName = dictionary[DeepLinkKeys.ScreenName] as? String
        pathID = dictionary[DeepLinkKeys.PathID] as? String
    }
}
