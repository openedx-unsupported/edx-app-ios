/**
Copyright (c) 2015 Qualcomm Education, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Qualcomm Education, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

import UIKit
import edXCore

// See https://openedx.atlassian.net/wiki/display/MA/Discussion+API

public struct DiscussionComment {
    var commentID: String
    var parentID: String?
    var threadID: String
    var rawBody: String?
    var renderedBody: String?
    var author: String? // user cannot add response as anonymous. AuthorLabelProtocol is shared by both DiscussionComment and DiscussionThread that's why its optional.
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
    var childCount = 0
    var hasProfileImage = false
    var imageURL: String?
}

extension DiscussionComment {
    init?(json: JSON) {
        guard let
            threadID = json["thread_id"].string,
            let commentID = json["id"].string,
            let author = json["author"].string else
        {
                return nil
        }

        parentID = json["parent_id"].string
        self.threadID = threadID
        self.commentID = commentID
        rawBody = json["raw_body"].string
        renderedBody = json["rendered_body"].string
        self.author = author
        authorLabel = json["author_label"].string
        voted = json["voted"].boolValue
        voteCount = json["vote_count"].intValue
        if let dateStr = json["created_at"].string {
            createdAt = DateFormatting.date(withServerString: dateStr)
        }
        if let dateStr = json["updated_at"].string {
            updatedAt = DateFormatting.date(withServerString: dateStr)
        }
        endorsed = json["endorsed"].boolValue
        endorsedBy = json["endorsed_by"].string
        endorsedByLabel = json["endorsed_by_label"].string
        if let dateStr = json["endorsed_at"].string {
            endorsedAt = DateFormatting.date(withServerString: dateStr)
        }
        flagged = json["flagged"].boolValue
        abuseFlagged = json["abuse_flagged"].boolValue
        editableFields = json["editable_fields"].string
        childCount = json["child_count"].intValue
        
        let users = json["users"].dictionary
        if let users = users{
            let user = users[author]?.dictionary
            if let user = user {
                let profile = user["profile"]
                if let profile = profile {
                    let image = profile["image"]
                    hasProfileImage = image["has_image"].boolValue
                    imageURL = image["image_url_medium"].string
                }
            }
        }
    }
}


public enum DiscussionThreadType : String {
    case Question = "question"
    case Discussion = "discussion"
}

public struct DiscussionThread {
    var threadID: String
    var type: DiscussionThreadType
    var courseId: String?
    var topicId: String
    var groupId: Int?
    var groupName: String?
    var title: String?
    var rawBody: String?
    var renderedBody: String?
    var author: String? // Posts by anonymous user have no author
    var authorLabel: String?
    var commentCount = 0
    var commentListUrl: String?
    var hasEndorsed = false
    var pinned = false
    var closed = false
    var following = false
    var flagged = false
    var abuseFlagged = false
    var voted = false
    var voteCount = 0
    var createdAt: NSDate?
    var updatedAt: NSDate?
    var editableFields: String?
    var read = false
    var unreadCommentCount = 0
    var responseCount : Int?
    var hasProfileImage = false
    var imageURL: String?
}

extension DiscussionThread {
    public init?(json: JSON) {
        guard let
            topicId = json["topic_id"].string,
            let identifier = json["id"].string
            else
        {
            return nil
        }
        
        threadID = identifier
        self.topicId = topicId
        
        author = json["author"].string
        type = DiscussionThreadType(rawValue: json["type"].string ?? "") ?? .Discussion
        courseId = json["course_id"].string
        groupId = json["group_id"].intValue
        groupName = json["group_name"].string
        title = json["title"].string
        rawBody = json["raw_body"].string
        renderedBody = json["rendered_body"].string
        authorLabel = json["author_label"].string
        commentCount = json["comment_count"].intValue
        commentListUrl = json["comment_list_url"].string
        hasEndorsed = json["has_endorsed"].boolValue
        pinned = json["pinned"].boolValue
        closed = json["closed"].boolValue
        following = json["following"].boolValue
        flagged = json["flagged"].boolValue
        abuseFlagged = json["abuse_flagged"].boolValue
        voted = json["voted"].boolValue
        voteCount = json["vote_count"].intValue
        read = json["read"].boolValue
        unreadCommentCount = json["unread_comment_count"].intValue
        
        if let dateStr = json["created_at"].string {
            createdAt = DateFormatting.date(withServerString: dateStr)
        }
        if let dateStr = json["updated_at"].string {
            updatedAt = DateFormatting.date(withServerString: dateStr)
        }
        self.editableFields = json["editable_fields"].string
        if let numberOfResponses = json["response_count"].int {
            responseCount = numberOfResponses
        }
        
        let users = json["users"].dictionary
        if let users = users, author != nil {
            let user = users[author!]?.dictionary
            if let user = user {
                let profile = user["profile"]
                if let profile = profile {
                    let image = profile["image"]
                    hasProfileImage = image["has_image"].boolValue
                    imageURL = image["image_url_medium"].string
                }
            }
        }
    }
}

public struct DiscussionInfo {
    var discussionID: String?
    var blackouts: [DiscussionBlackout]?
    var isBlackedOut = false
}

extension DiscussionInfo {
    public init?(json: JSON) {
        guard let discussionID = json["id"].string, let blackouts = json.dictionaryValue["blackouts"]?.arrayValue, blackouts.count > 0 else { return }
        
        self.discussionID = discussionID
        self.blackouts = [DiscussionBlackout]()
        for blackout in blackouts {
            if let discussionBlackout = DiscussionBlackout(json: blackout) {
                self.blackouts?.append(discussionBlackout)
                if NSDate().isEarlierThanOrEqual(to: discussionBlackout.end as Date) && NSDate().isLaterThanOrEqual(to: discussionBlackout.start as Date) {
                    isBlackedOut = true
                }
            }
        }
    }
}

public struct DiscussionBlackout {
    var start: NSDate
    var end: NSDate
}

extension DiscussionBlackout {
    public init?(json: JSON) {
        guard let startDateString = json["start"].string, let endDateString = json["end"].string else { return nil }
        guard let startDate = DateFormatting.date(withServerString: startDateString), let endDate = DateFormatting.date(withServerString: endDateString) else { return nil }
        start = startDate
        end = endDate
    }
}

