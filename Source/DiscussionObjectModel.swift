//
//  DiscussionObjectModel.swift
//  edX
//
//  Created by Lim, Jake on 6/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class DiscussionThread: NSObject {
    var identifier: String!
    var type: String!
    var courseId: String!
    var topicId: String!
    var groupId: String!
    var groupName: String!
    var title: String!
    var rawBody: String!
    var renderedBody: String!
    var author: String!
    var authorLabel: String!
    var commentListUrl: String!
    var hasEndorsed = false
    var pinned = false
    var closed = false
    var following = false
    var abuseFlagged = false
    var voted = false
    var voteCount = 0
    var createdAt: NSDate!
    var modifiedAt: NSDate!
    var editableFields: String!
}

class DiscussionComment: NSObject {
    var identifier: String!
    var parentId: String!
    var threadId: String!
    var rawBody: String!
    var renderedBody: String!
    var author: String!
    var authorLabel: String!
    var flagged = false
    var voted = false
    var voteCount = 0
    var createdAt: NSDate!
    var updatedAt: NSDate!
    var endorsed = false
    var endorsedBy: String!
    var endorsedByLabel: String!
    var endorsedAt: NSDate!
    var abuseFlagged = false
    var editableFields: String!
    var children: [DiscussionComment]!
}
