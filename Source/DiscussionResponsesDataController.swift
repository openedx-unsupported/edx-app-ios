//
//  DiscussionResponsesDataController.swift
//  edX
//
//  Created by Saeed Bashir on 2/24/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class DiscussionResponsesDataController: NSObject {
 
    var responses: [DiscussionComment] = []
    var endorsedResponses: [DiscussionComment] = []
    
    /// "Given a new comment, looks through responses and increments the childCount of the parent of that comment."
    func addedChildComment(comment: DiscussionComment) {
        for i in 0 ..< responses.count {
            if responses[i].commentID == comment.parentID {
                responses[i].childCount += 1
                break
            }
        }
        
        for i in 0..<endorsedResponses.count {
            if endorsedResponses[i].commentID == comment.parentID {
                endorsedResponses[i].childCount += 1
                break
            }
        }
    }

    /// "Given a new comment, looks through responses and update vote information of that comment."
    func updateCommentVote(comment: DiscussionComment) {
        for i in 0 ..< responses.count {
            if responses[i].commentID == comment.commentID {
                responses[i].voted = comment.voted
                responses[i].voteCount = comment.voteCount
                break
            }
        }
        
        for i in 0..<endorsedResponses.count {
            if endorsedResponses[i].commentID == comment.commentID {
                endorsedResponses[i].voted = comment.voted
                endorsedResponses[i].voteCount = comment.voteCount
                break
            }
        }
    }
    
    /// "Given a new comment, looks through responses and update report abuse flag of that comment."
    func updateCommentReport(comment: DiscussionComment) {
        for i in 0 ..< responses.count {
            if responses[i].commentID == comment.commentID {
                responses[i].abuseFlagged = comment.abuseFlagged
                break
            }
        }
        
        for i in 0..<endorsedResponses.count {
            if endorsedResponses[i].commentID == comment.commentID {
                endorsedResponses[i].abuseFlagged = comment.abuseFlagged
                break
            }
        }
    }
}