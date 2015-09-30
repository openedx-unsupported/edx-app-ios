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

public struct DiscussionComment {
    var commentID: String
    var parentId: String?
    var threadId: String?
    var rawBody: String?
    var renderedBody: String?
    var author: String?
    var authorLabel: AuthorLabelType?
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
            commentID = identifier
            parentId = json["parent_id"].string
            threadId = json["thread_id"].string
            rawBody = json["raw_body"].string
            renderedBody = json["rendered_body"].string
            author = json["author"].string
            if let authorLabelString = json["author_label"].string {
                self.authorLabel = AuthorLabelType(rawValue: authorLabelString)
            }
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


public enum PostThreadType : String {
    case Question = "question"
    case Discussion = "discussion"
}

public enum AuthorLabelType : String {
    case Staff = "staff"
    case CommunityTA = "community_ta"
    
    var localizedString : String {
        switch self {
        case .Staff:
            return OEXLocalizedString("STAFF", nil)
        case .CommunityTA:
            return OEXLocalizedString("COMMUNITY_TA", nil)
        }
    }
}

struct DiscussionThread {
    var identifier: String?
    var type: PostThreadType?
    var courseId: String?
    var topicId: String?
    var groupId: Int?
    var groupName: String?
    var title: String?
    var rawBody: String?
    var renderedBody: String?
    var author: String?
    var authorLabel: AuthorLabelType?
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
    
    init?(json: JSON) {
        if let identifier = json["id"].string {
            self.identifier = identifier
            type = PostThreadType(rawValue: json["type"].string ?? "")
            courseId = json["course_id"].string
            topicId = json["topic_id"].string
            groupId = json["group_id"].intValue
            groupName = json["group_name"].string
            title = json["title"].string
            rawBody = json["raw_body"].string
            renderedBody = json["rendered_body"].string
            author = json["author"].string
            if let authorLabelString = json["author_label"].string {
                authorLabel = AuthorLabelType(rawValue: authorLabelString)
            }
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
