//
//  DiscussionObjectModel.swift
//  edX
//
//  Created by Lim, Jake on 6/2/15.
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

class DiscussionComment {
    var identifier: String?
    var parentId: String?
    var threadId: String?
    var rawBody: String?
    var renderedBody: String?
    var author: String?
    var authorLabel: String?
    var voted = false
    var voteCount = 0
    var createdAt: NSDate?
    var updatedAt: NSDate?
    var endorsed = false
    var endorsedBy: String?
    var endorsedByLabel: String?
    var endorsedAt: NSDate?
    var abuseFlagged = false
    var editableFields: String?
    var children: [DiscussionComment]?
    
    init?(json: JSON) {
        if let identifier = json["id"].string {
            self.identifier = identifier
            parentId = json["parent_id"].string
            threadId = json["thread_id"].string
            rawBody = json["raw_body"].string
            renderedBody = json["rendered_body"].string
            author = json["author"].string
            authorLabel = json["author_label"].string
            voted = json["voted"].boolValue
            voteCount = json["vote_count"].intValue
            if let dateStr = json["created_at"].string {
                createdAt = OEXDateFormatting.dateWithServerString(dateStr)
            }
            if let dateStr = json["updated_at"].string {
                updatedAt = OEXDateFormatting.dateWithServerString(dateStr)
            }
            endorsed = json["endorsed"].boolValue
            endorsedBy = json["endorsed_by"].string
            endorsedByLabel = json["endorsed_by_label"].string
            if let dateStr = json["endorsed_at"].string {
                endorsedAt = OEXDateFormatting.dateWithServerString(dateStr)
            }
            abuseFlagged = json["abuse_flagged"].boolValue
            editableFields = json["editable_fields"].string
            if let childrenJson = json["children"].arrayObject {
                var children = [DiscussionComment]()
                for childJson in childrenJson {
                    if let child = DiscussionComment(json: childJson as! JSON) {
                        children.append(child)
                    }
                }
                self.children = children
            }
        } else {
            return nil
        }
    }
}
