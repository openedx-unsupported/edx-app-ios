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
    case courseDates = "course_dates"
    case courseHandout = "course_handout"
    case courseComponent = "course_component"
    case courseAnnouncement = "course_announcement"
    case discussionTopic = "discussion_topic"
    case discussionPost = "discussion_post"
    case discussionComment = "discussion_comment"
    case discovery = "discovery"
    case discoveryCourseDetail = "discovery_course_detail"
    case discoveryProgramDetail = "discovery_program_detail"
    case program = "program"
    case programDetail = "program_detail"
    case userProfile = "user_profile"
    case profile = "profile"
    case settings = "settings"
    case none = "none"
}

enum DeepLinkKeys: String, RawStringExtractable {
    case courseId = "course_id"
    case pathID = "path_id"
    case screenName = "screen_name"
    case topicID = "topic_id"
    case threadID = "thread_id"
    case commentID = "comment_id"
    case componentID = "component_id"
}

class DeepLink: NSObject {
    let courseId: String?
    let screenName: String?
    let pathID: String?
    let topicID: String?
    let threadID: String?
    let commentID: String?
    let componentID: String?
    
    var type: DeepLinkType {
        let type = DeepLinkType(rawValue: screenName ?? DeepLinkType.none.rawValue) ?? .none

        if type == .discovery {
            return .discovery
        }
        else if type == .discoveryCourseDetail && courseId != nil {
            return .discoveryCourseDetail
        }
        else if type == .program && pathID != nil {
            return .programDetail
        }
        else if type == .discoveryProgramDetail && pathID != nil {
            return .discoveryProgramDetail
        }
        return type
    }
    
    init(dictionary: [String : Any]) {
        courseId = dictionary[DeepLinkKeys.courseId] as? String
        screenName = dictionary[DeepLinkKeys.screenName] as? String
        pathID = dictionary[DeepLinkKeys.pathID] as? String
        topicID = dictionary[DeepLinkKeys.topicID] as? String
        threadID = dictionary[DeepLinkKeys.threadID] as? String
        commentID = dictionary[DeepLinkKeys.commentID] as? String
        componentID = dictionary[DeepLinkKeys.componentID] as? String
    }
}
