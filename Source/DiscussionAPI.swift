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
    case MostActivity
    case VoteCount
    
    private var apiRepresentation : String? {
        switch self {
        case RecentActivity: return "last_activity_at"
        case MostActivity: return "comment_count"
        case VoteCount: return "vote_count"
        }
    }
}


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
            for topics in [nonCoursewareTopics, coursewareTopics] {
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

    //MA-1378 - Automatically follow posts when creating a new post
    static func createNewThread(newThread: DiscussionNewThread, follow : Bool = true) -> NetworkRequest<DiscussionThread> {
        let json = JSON([
            "course_id" : newThread.courseID,
            "topic_id" : newThread.topicID,
            "type" : newThread.type.rawValue,
            "title" : newThread.title,
            "raw_body" : newThread.rawBody,
            "following" : follow
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
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
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
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
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
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
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
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
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
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer : .JSONResponse(threadDeserializer)
        )
    }    
    
    // mark thread as read
    static func readThread(read: Bool, threadID: String) -> NetworkRequest<DiscussionThread> {
        let json = JSON(["read" : read])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
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
        query[PaginationDefaults.pageParam] = JSON(pageNumber)
        query[PaginationDefaults.pageSizeParam] = JSON(PaginationDefaults.pageSize)
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: query,
            requiresAuth : true,
            deserializer : .JSONResponse(threadListDeserializer)
        )
    }
    
    static func getThreadByID(threadID : String) -> NetworkRequest<DiscussionThread> {
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            deserializer : .JSONResponse(threadDeserializer)
        )
    }
    
    static func getFollowedThreads(courseID courseID : String, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort, pageNumber : Int = 1) -> NetworkRequest<[DiscussionThread]> {
        var query = ["course_id" : JSON(courseID), "following" : JSON(true) ]
        if let view = filter.apiRepresentation {
            query["view"] = JSON(view)
        }
        if let order = orderBy.apiRepresentation {
            query["order_by"] = JSON(order)
        }
        query[PaginationDefaults.pageParam] = JSON(pageNumber)
        query[PaginationDefaults.pageSizeParam] = JSON(PaginationDefaults.pageSize)
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: query,
            requiresAuth : true,
            deserializer : .JSONResponse(threadListDeserializer)
        )

    }
    
    static func searchThreads(courseID courseID: String, searchText: String, pageNumber : Int = 1) -> NetworkRequest<[DiscussionThread]> {
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: [
                "course_id" : JSON(courseID),
                "text_search": JSON(searchText),
                PaginationDefaults.pageParam : JSON(pageNumber),
                PaginationDefaults.pageSizeParam : JSON(PaginationDefaults.pageSize)
            ],
            requiresAuth : true,
            deserializer : .JSONResponse(threadListDeserializer)
        )
    }
    
    //TODO: Yet to decide the semantics for the *endorsed* field. Setting false by default to fetch all questions.
    //Questions can not be fetched if the endorsed field isn't populated
    static func getResponses(threadID: String,  threadType : DiscussionThreadType, endorsedOnly endorsed : Bool =  false, pageNumber : Int = 1) -> NetworkRequest<[DiscussionComment]> {
        var query = [
            PaginationDefaults.pageParam : JSON(pageNumber),
            PaginationDefaults.pageSizeParam : JSON(PaginationDefaults.pageSize),
            "thread_id": JSON(threadID),
        ]
        
        //Only set the endorsed flag if the post is a question
        if threadType == .Question {
            query["endorsed"] = JSON(endorsed)
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
    
    // get response comments
    static func getComments(commentID: String, pageNumber: Int) -> NetworkRequest<[DiscussionComment]> {
        
        let query = [
            PaginationDefaults.pageParam : JSON(pageNumber),
            PaginationDefaults.pageSizeParam : JSON(PaginationDefaults.pageSize),
        ]
        
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/comments/\(commentID)/",
            query: query,
            requiresAuth : true,
            deserializer : .JSONResponse(commentListDeserializer)
        )
    }

}
