//
//  DiscussionComment.swift
//  edX
//
//  Created by Akiva Leffert on 7/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

struct DiscussionComment {
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
    var flagged = false
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
            flagged = json["flagged"].boolValue
            abuseFlagged = json["abuse_flagged"].boolValue
            editableFields = json["editable_fields"].string
            if let childrenJson = json["children"].array {
                var children = [DiscussionComment]()
                for childJson in childrenJson {
                    if let child = DiscussionComment(json: childJson) {
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
