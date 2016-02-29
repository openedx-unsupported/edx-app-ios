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

// See https://openedx.atlassian.net/wiki/display/MA/Discussion+API

public struct DiscussionComment {
    var commentID: String
    var parentID: String?
    var threadID: String
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
    var childCount = 0
    
}

extension DiscussionComment {
    init?(json: JSON) {
        guard let
            threadID = json["thread_id"].string,
            commentID = json["id"].string,
            author = json["author"].string else
        {
                return nil
        }

        self.parentID = json["parent_id"].string
        self.threadID = threadID
        self.commentID = commentID
        self.rawBody = json["raw_body"].string
        self.renderedBody = json["rendered_body"].string
        self.author = author
        self.authorLabel = json["author_label"].string
        self.voted = json["voted"].boolValue
        self.voteCount = json["vote_count"].intValue
        if let dateStr = json["created_at"].string {
            self.createdAt = OEXDateFormatting.dateWithServerString(dateStr)
        }
        if let dateStr = json["updated_at"].string {
            self.updatedAt = OEXDateFormatting.dateWithServerString(dateStr)
        }
        self.endorsed = json["endorsed"].boolValue
        self.endorsedBy = json["endorsed_by"].string
        self.endorsedByLabel = json["endorsed_by_label"].string
        if let dateStr = json["endorsed_at"].string {
            self.endorsedAt = OEXDateFormatting.dateWithServerString(dateStr)
        }
        self.flagged = json["flagged"].boolValue
        self.abuseFlagged = json["abuse_flagged"].boolValue
        self.editableFields = json["editable_fields"].string
        self.childCount = json["child_count"].intValue
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
    var author: String?
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
}

extension DiscussionThread {
    public init?(json: JSON) {
        guard let
            topicId = json["topic_id"].string,
            identifier = json["id"].string
            else
        {
            return nil
        }
        
        if let author =  json["author"].string {
            self.author = author
        }
        
        self.threadID = identifier
        self.topicId = topicId
        
        self.type = DiscussionThreadType(rawValue: json["type"].string ?? "") ?? .Discussion
        self.courseId = json["course_id"].string
        self.groupId = json["group_id"].intValue
        self.groupName = json["group_name"].string
        self.title = json["title"].string
        self.rawBody = json["raw_body"].string
        self.renderedBody = json["rendered_body"].string
        self.authorLabel = json["author_label"].string
        self.commentCount = json["comment_count"].intValue
        self.commentListUrl = json["comment_list_url"].string
        self.hasEndorsed = json["has_endorsed"].boolValue
        self.pinned = json["pinned"].boolValue
        self.closed = json["closed"].boolValue
        self.following = json["following"].boolValue
        self.flagged = json["flagged"].boolValue
        self.abuseFlagged = json["abuse_flagged"].boolValue
        self.voted = json["voted"].boolValue
        self.voteCount = json["vote_count"].intValue
        self.read = json["read"].boolValue
        self.unreadCommentCount = json["unread_comment_count"].intValue
        
        if let dateStr = json["created_at"].string {
            self.createdAt = OEXDateFormatting.dateWithServerString(dateStr)
        }
        if let dateStr = json["updated_at"].string {
            self.updatedAt = OEXDateFormatting.dateWithServerString(dateStr)
        }
        self.editableFields = json["editable_fields"].string
        if let numberOfResponses = json["response_count"].int {
            self.responseCount = numberOfResponses
        }
    }
}
