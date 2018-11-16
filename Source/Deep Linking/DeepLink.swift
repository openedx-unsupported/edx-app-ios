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
    case programs = "program"
    case account = "account"
    case none = "none"
}

fileprivate enum DeepLinkKeys: String, RawStringExtractable {
    case CourseId = "course_id"
    case ScreenName = "screen_name"
}

class DeepLink: NSObject {

    let courseId: String?
    let screenName: String?
    private(set) var type: DeepLinkType = .none
    
    init(dictionary:[String:Any]) {
        courseId = dictionary[DeepLinkKeys.CourseId] as? String
        screenName = dictionary[DeepLinkKeys.ScreenName] as? String
        type = DeepLinkType(rawValue: screenName ?? DeepLinkType.none.rawValue) ?? .none
    }
}
