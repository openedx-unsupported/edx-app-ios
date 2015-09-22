//
//  DiscussionAPI.swift
//  edX
//
//  Created by Tang, Jeff on 6/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public enum DiscussionPostsFilter {
    case AllPosts
    case Unread
    case Unanswered
    
    private var apiRepresentation : String? {
        switch self {
        case AllPosts: return nil // default
        case Unread: return "unread"
        case Unanswered: return "unanswered"
        }
    }
}

public enum DiscussionPostsSort {
    case RecentActivity
    case LastActivityAt
    case VoteCount
    
    private var apiRepresentation : String? {
        switch self {
        case RecentActivity: return nil // default
        case LastActivityAt: return "last_activity_at"
        case VoteCount: return "vote_count"
        }
    }
    
    var icon : Icon {
        switch (self) {
        case .RecentActivity, .LastActivityAt:
            return Icon.Comment
        case .VoteCount:
            return Icon.UpVote
        }
    }
}

extension Bool {
    //It's existence depends on the resolution of MA-1211
    var edxServerString : String {
        return self ? "True" : "False"
    }
}

public let defaultPageSize : Int = 20

public class DiscussionAPI {
    
    
    
    private static func threadDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<DiscussionThread> {
        return DiscussionThread(json : json).toResult(NSError.oex_courseContentLoadError())
    }
    
    private static func commentDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<DiscussionComment> {
        return DiscussionComment(json : json).toResult(NSError.oex_courseContentLoadError())
    }
    
    private static func listDeserializer<A>(response : NSHTTPURLResponse, json : JSON, constructor : (JSON -> A?)) -> Result<[A]> {
        if let items = json["results"].array {
            var result: [A] = []
            for itemJSON in items {
                if let item = constructor(itemJSON) {
                    result.append(item)
                }
            }
            return Success(result)
        }
        else {
            return Failure(NSError.oex_courseContentLoadError())
        }
    }
    
    private static func threadListDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<[DiscussionThread]> {
        return listDeserializer(response, json: json, constructor: { DiscussionThread(json : $0) } )
    }
    
    private static func commentListDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<[DiscussionComment]> {
        return listDeserializer(response, json: json, constructor: { DiscussionComment(json : $0) } )
    }

    private static func topicListDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<[DiscussionTopic]> {
        if let coursewareTopics = json["courseware_topics"].array,
            nonCoursewareTopics = json["non_courseware_topics"].array
        {
            var result: [DiscussionTopic] = []
            for topics in [coursewareTopics, nonCoursewareTopics] {
                for json in topics {
                    if let topic = DiscussionTopic(json: json) {
                        result.append(topic)
                    }
                }
            }
            return Success(result)
        }
        else {
            return Failure(NSError.oex_courseContentLoadError())
        }
    }

    static func createNewThread(newThread: DiscussionNewThread) -> NetworkRequest<DiscussionThread> {
        let json = JSON([
            "course_id" : newThread.courseID,
            "topic_id" : newThread.topicID,
            "type" : newThread.type.rawValue,
            "title" : newThread.title,
            "raw_body" : newThread.rawBody,
            ])
        return NetworkRequest(
            method : HTTPMethod.POST,
            path : "/api/discussion/v1/threads/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : .JSONResponse(threadDeserializer)
        )
    }
    
    // when parent id is nil, counts as a new post
    static func createNewComment(threadID : String, text : String, parentID : String? = nil) -> NetworkRequest<DiscussionComment> {
        var json = JSON([
            "thread_id" : threadID,
            "raw_body" : text,
            ])
        
        if let parentID = parentID {
            json["parent_id"] = JSON(parentID)
        }
        
        return NetworkRequest(
            method : HTTPMethod.POST,
            path : "/api/discussion/v1/comments/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : .JSONResponse(commentDeserializer)
        )
    }
    
    // User can only vote on post and response not on comment.
    // thread is the same as post
    static func voteThread(voted: Bool, threadID: String) -> NetworkRequest<DiscussionThread> {
        let json = JSON(["voted" : !voted])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : .JSONResponse(threadDeserializer)
        )
    }
    
    static func voteResponse(voted: Bool, responseID: String) -> NetworkRequest<DiscussionComment> {
        let json = JSON(["voted" : !voted])        
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/comments/\(responseID)/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : .JSONResponse(commentDeserializer)
        )
    }
    
    // User can flag (report) on post, response, or comment
    static func flagThread(flagged: Bool, threadID: String) -> NetworkRequest<DiscussionThread> {
        let json = JSON(["flagged" : flagged])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : .JSONResponse(threadDeserializer)
        )
    }
    
    static func flagComment(flagged: Bool, commentID: String) -> NetworkRequest<DiscussionComment> {
        let json = JSON(["flagged" : flagged])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/comments/\(commentID)/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : .JSONResponse(commentDeserializer)
        )
    }
   
    // User can only follow original post, not response or comment.    
    static func followThread(following: Bool, threadID: String) -> NetworkRequest<DiscussionThread> {
        let json = JSON(["following" : !following])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : .JSONResponse(threadDeserializer)
        )
    }    
    
    // Pass nil in place of topicIDs if we need to fetch all threads
    static func getThreads(courseID courseID: String, topicIDs: [String]?, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort, pageNumber : Int) -> NetworkRequest<[DiscussionThread]> {
        var query = ["course_id" : JSON(courseID)]
        if let identifiers = topicIDs {
            //TODO: Replace the comma separated strings when the API improves
            query["topic_id"] = JSON(identifiers.joinWithSeparator(","))
        }
        if let view = filter.apiRepresentation {
            query["view"] = JSON(view)
        }
        if let order = orderBy.apiRepresentation {
            query["order_by"] = JSON(order)
        }
        query["page_size"] = JSON(defaultPageSize)
        query["page"] = JSON(pageNumber)
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: query,
            requiresAuth : true,
            deserializer : .JSONResponse(threadListDeserializer)
        )
    }
    
    static func getFollowedThreads(courseID courseID : String, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort, pageNumber : Int = 1) -> NetworkRequest<[DiscussionThread]> {
        var query = ["course_id" : JSON(courseID), "following" : JSON(true.edxServerString) ]
        if let view = filter.apiRepresentation {
            query["view"] = JSON(view)
        }
        if let order = orderBy.apiRepresentation {
            query["order_by"] = JSON(order)
        }
        query["page_size"] = JSON(defaultPageSize)
        query["page"] = JSON(pageNumber)
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: query,
            requiresAuth : true,
            deserializer : .JSONResponse(threadListDeserializer)
        )

    }
    
    static func searchThreads(courseID courseID: String, searchText: String) -> NetworkRequest<[DiscussionThread]> {
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: ["course_id" : JSON(courseID), "text_search": JSON(searchText)],
            requiresAuth : true,
            deserializer : .JSONResponse(threadListDeserializer)
        )
    }
    
    //TODO: Yet to decide the semantics for the *endorsed* field. Setting false by default to fetch all questions.
    //Questions can not be fetched if the endorsed field isn't populated
    static func getResponses(threadID: String,  threadType : PostThreadType, markAsRead : Bool, endorsedOnly endorsed : Bool =  false, pageNumber : Int = 1) -> NetworkRequest<[DiscussionComment]> {
        var query = [
            "page_size" : JSON(defaultPageSize),
            "page" : JSON(pageNumber),
            "thread_id": JSON(threadID),
            "mark_as_read" : JSON(markAsRead)
        ]
        
        //Only set the endorsed flag if the post is a question
        if threadType == .Question {
            query["endorsed"] = JSON(endorsed.edxServerString)
        }
        
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/comments/", // responses are treated similarly as comments
            query: query,
            requiresAuth : true,
            deserializer : .JSONResponse(commentListDeserializer)
        )
    }
    
    static func getCourseTopics(courseID: String) -> NetworkRequest<[DiscussionTopic]> {
        return NetworkRequest(
                method : HTTPMethod.GET,
                path : "/api/discussion/v1/course_topics/\(courseID)",
                requiresAuth : true,
                deserializer : .JSONResponse(topicListDeserializer)
        )
    }

}