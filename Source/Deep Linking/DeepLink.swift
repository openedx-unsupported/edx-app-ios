//
//  DeepLink.swift
//  edX
//
//  Created by Salman on 02/10/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

enum DeepLinkType: String {
    case CourseDashboard = "course_dashboard"
    case CourseVideos = "course_videos"
    case Discussions = "course_discussion"
    case None = "none"
}

fileprivate enum DeepLinkKeys: String, RawStringExtractable {
    case CourseId = "course_id"
    case ScreenName = "screen_name"
}

class DeepLink: NSObject {

    let courseId: String?
    let screenName: String?
    let type: DeepLinkType?
    
    init(dictionary:[String:Any]) {
        courseId = dictionary[DeepLinkKeys.CourseId] as? String
        screenName = dictionary[DeepLinkKeys.ScreenName] as? String
        type = DeepLinkType(rawValue: screenName ?? DeepLinkType.None.rawValue) ?? .None
    }
}
