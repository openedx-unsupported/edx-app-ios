//
//  DiscussionThread.swift
//  edX
//
//  Created by Akiva Leffert on 7/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class DiscussionThread {
    var identifier: String?
    var type: String?
    var courseId: String?
    var topicId: String?
    var groupId: Int?
    var groupName: String?
    var title: String?
    var rawBody: String?
    var renderedBody: String?
    var author: String?
    var authorLabel: String?
    var commentCount = 0
    var commentListUrl: String?
    var hasEndorsed = false
    var pinned = false
    var closed = false
    var following = false
    var abuseFlagged = false
    var voted = false
    var voteCount = 0
    var createdAt: NSDate?
    var updatedAt: NSDate?
    var editableFields: String?
    
    init?(json: JSON) {
        if let identifier = json["id"].string {
            self.identifier = identifier
            type = json["type"].string
            courseId = json["course_id"].string
            topicId = json["topic_id"].string
            groupId = json["group_id"].intValue
            groupName = json["group_name"].string
            title = json["title"].string
            rawBody = json["raw_body"].string
            renderedBody = json["rendered_body"].string
            author = json["author"].string
            authorLabel = json["author_label"].string
            commentCount = json["comment_count"].intValue
            commentListUrl = json["comment_list_url"].string
            hasEndorsed = json["has_endorsed"].boolValue
            pinned = json["pinned"].boolValue
            closed = json["closed"].boolValue
            following = json["following"].boolValue
            abuseFlagged = json["abuse_flagged"].boolValue
            voted = json["voted"].boolValue
            voteCount = json["vote_count"].intValue
            if let dateStr = json["created_at"].string {
                createdAt = OEXDateFormatting.dateWithServerString(dateStr)
            }
            if let dateStr = json["updated_at"].string {
                updatedAt = OEXDateFormatting.dateWithServerString(dateStr)
            }
            editableFields = json["editable_fields"].string
        } else {
            return nil
        }
    }
}