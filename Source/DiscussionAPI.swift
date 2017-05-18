//
//  DiscussionAPI.swift
//  edX
//
//  Created by Tang, Jeff on 6/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public enum DiscussionPostsFilter {
    case AllPosts
    case Unread
    case Unanswered
    
    fileprivate var apiRepresentation : String? {
        switch self {
        case .AllPosts: return nil // default
        case .Unread: return "unread"
        case .Unanswered: return "unanswered"
        }
    }
}

public enum DiscussionPostsSort {
    case RecentActivity
    case MostActivity
    case VoteCount
    
    fileprivate var apiRepresentation : String? {
        switch self {
        case .RecentActivity: return "last_activity_at"
        case .MostActivity: return "comment_count"
        case .VoteCount: return "vote_count"
        }
    }
}


public class DiscussionAPI {

    private static func threadDeserializer(response : HTTPURLResponse, json : JSON) -> Result<DiscussionThread> {
        return DiscussionThread(json : json).toResult(NSError.oex_courseContentLoadError())
    }
    
    private static func commentDeserializer(response : HTTPURLResponse, json : JSON) -> Result<DiscussionComment> {
        return DiscussionComment(json : json).toResult(NSError.oex_courseContentLoadError())
    }
    
    private static func listDeserializer<A>(response : HTTPURLResponse, items : [JSON]?, constructor : ((JSON) -> A?)) -> Result<[A]> {
        
        if let items = items {
            var result: [A] = []
            for itemJSON in items {
                if let item = constructor(itemJSON) {
                    result.append(item)
                }
            }
            return Success(v: result)
        }
        else {
            return Failure(e: NSError.oex_courseContentLoadError())
        }
    }
    
    private static func threadListDeserializer(response : HTTPURLResponse, json : JSON) -> Result<[DiscussionThread]> {
        return listDeserializer(response: response, items: json.array, constructor: { DiscussionThread(json : $0) } )
    }
    
    private static func commentListDeserializer(response : HTTPURLResponse, json : JSON) -> Result<[DiscussionComment]> {
        return listDeserializer(response: response, items: json.array, constructor: { DiscussionComment(json : $0) } )
    }

    private static func topicListDeserializer(response : HTTPURLResponse, json : JSON) -> Result<[DiscussionTopic]> {
        if let coursewareTopics = json["courseware_topics"].array,
            let nonCoursewareTopics = json["non_courseware_topics"].array
        {
            var result: [DiscussionTopic] = []
            for topics in [nonCoursewareTopics, coursewareTopics] {
                for json in topics {
                    if let topic = DiscussionTopic(json: json) {
                        result.append(topic)
                    }
                }
            }
            return Success(v: result)
        }
        else {
            return Failure(e: NSError.oex_courseContentLoadError())
        }
    }
    
    private static func discussionInfoDeserializer(response : HTTPURLResponse, json : JSON) -> Result<DiscussionInfo> {
        return DiscussionInfo(json : json).toResult(NSError.oex_courseContentLoadError())
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
            body: RequestBody.jsonBody(json),
            deserializer : .jsonResponse(threadDeserializer)
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
            body: RequestBody.jsonBody(json),
            deserializer : .jsonResponse(commentDeserializer)
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
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer : .jsonResponse(threadDeserializer)
        )
    }
    
    static func voteResponse(voted: Bool, responseID: String) -> NetworkRequest<DiscussionComment> {
        let json = JSON(["voted" : !voted])        
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/comments/\(responseID)/",
            requiresAuth : true,
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer : .jsonResponse(commentDeserializer)
        )
    }
    
    // User can flag (report) on post, response, or comment
    static func flagThread(abuseFlagged: Bool, threadID: String) -> NetworkRequest<DiscussionThread> {
        let json = JSON(["abuse_flagged" : abuseFlagged])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer : .jsonResponse(threadDeserializer)
        )
    }
    
    static func flagComment(abuseFlagged: Bool, commentID: String) -> NetworkRequest<DiscussionComment> {
        let json = JSON(["abuse_flagged" : abuseFlagged])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/comments/\(commentID)/",
            requiresAuth : true,
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer : .jsonResponse(commentDeserializer)
        )
    }
   
    // User can only follow original post, not response or comment.    
    static func followThread(following: Bool, threadID: String) -> NetworkRequest<DiscussionThread> {
        let json = JSON(["following" : !following])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer : .jsonResponse(threadDeserializer)
        )
    }    
    
    // mark thread as read
    static func readThread(read: Bool, threadID: String) -> NetworkRequest<DiscussionThread> {
        let json = JSON(["read" : read])
        return NetworkRequest(
            method : HTTPMethod.PATCH,
            path : "/api/discussion/v1/threads/\(threadID)/",
            requiresAuth : true,
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer : .jsonResponse(threadDeserializer)
        )
    }
    
    // Pass nil in place of topicIDs if we need to fetch all threads
    static func getThreads(environment: RouterEnvironment?, courseID: String, topicIDs: [String]?, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort, pageNumber : Int) -> NetworkRequest<Paginated<[DiscussionThread]>> {
        var query = ["course_id" : JSON(courseID)]
        addRequestedFields(environment: environment, query: &query)
        if let identifiers = topicIDs {
            //TODO: Replace the comma separated strings when the API improves
            query["topic_id"] = JSON(identifiers.joined(separator: ","))
        }
        if let view = filter.apiRepresentation {
            query["view"] = JSON(view)
        }
        if let order = orderBy.apiRepresentation {
            query["order_by"] = JSON(order)
        }

        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            requiresAuth : true,
            query: query,
            deserializer : .jsonResponse(threadListDeserializer)
        ).paginated(page: pageNumber)
    }
    
    static func getFollowedThreads(environment: RouterEnvironment?, courseID : String, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort, pageNumber : Int = 1) -> NetworkRequest<Paginated<[DiscussionThread]>> {
        var query = ["course_id" : JSON(courseID), "following" : JSON(true)]
        addRequestedFields(environment: environment, query: &query)
        if let view = filter.apiRepresentation {
            query["view"] = JSON(view)
        }
        if let order = orderBy.apiRepresentation {
            query["order_by"] = JSON(order)
        }
        
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            requiresAuth : true,
            query: query,
            deserializer : .jsonResponse(threadListDeserializer)
        ).paginated(page: pageNumber)

    }
    
    static func searchThreads(environment: RouterEnvironment?, courseID: String, searchText: String, pageNumber : Int = 1) -> NetworkRequest<Paginated<[DiscussionThread]>> {
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            requiresAuth : true,
            query: [
                "course_id" : JSON(courseID),
                "text_search": JSON(searchText)
            ],
            deserializer : .jsonResponse(threadListDeserializer)
        ).paginated(page: pageNumber)
    }
    
    //TODO: Yet to decide the semantics for the *endorsed* field. Setting false by default to fetch all questions.
    //Questions can not be fetched if the endorsed field isn't populated
    static func getResponses(environment:RouterEnvironment?, threadID: String,  threadType : DiscussionThreadType, endorsedOnly endorsed : Bool =  false,pageNumber : Int = 1) -> NetworkRequest<Paginated<[DiscussionComment]>> {
        
        var query = ["thread_id": JSON(threadID)]
        if let environment = environment, environment.config.discussionsEnabledProfilePictureParam {
            query["requested_fields"] = JSON("profile_image")
        }
        
        //Only set the endorsed flag if the post is a question
        if threadType == .Question {
            query["endorsed"] = JSON(endorsed)
        }
        
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/comments/", // responses are treated similarly as comments
            requiresAuth : true,
            query: query,
            deserializer : .jsonResponse(commentListDeserializer)
        ).paginated(page: pageNumber)
    }
    
    private static func addRequestedFields(environment: RouterEnvironment?, query: inout [String : JSON]) {
        if let environment = environment, environment.config.discussionsEnabledProfilePictureParam {
            query["requested_fields"] = JSON("profile_image")
        }
    }
    
    static func getCourseTopics(courseID: String) -> NetworkRequest<[DiscussionTopic]> {
        return NetworkRequest(
                method : HTTPMethod.GET,
                path : "/api/discussion/v1/course_topics/\(courseID)",
                requiresAuth : true,
                deserializer : .jsonResponse(topicListDeserializer)
        )
    }
    
    static func getTopicByID(courseID: String, topicID : String) -> NetworkRequest<[DiscussionTopic]> {
        let query = ["topic_id" : JSON(topicID)]
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/course_topics/\(courseID)",
            requiresAuth : true,
            query: query,
            deserializer : .jsonResponse(topicListDeserializer)
        )
    }
    
    // get response comments
    static func getComments(environment:RouterEnvironment?, commentID: String, pageNumber: Int) -> NetworkRequest<Paginated<[DiscussionComment]>> {
        
        var query: [String: JSON] = [:]
        if let environment = environment, environment.config.discussionsEnabledProfilePictureParam {
            query["requested_fields"] = JSON("profile_image")
        }
        
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/comments/\(commentID)/",
            requiresAuth : true,
            query: query,
            deserializer : .jsonResponse(commentListDeserializer)
        ).paginated(page: pageNumber)
    }
    
    static func getDiscussionInfo(courseID: String) -> NetworkRequest<(DiscussionInfo)> {
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/courses/\(courseID)",
            requiresAuth : true,
            query: [:],
            deserializer : .jsonResponse(discussionInfoDeserializer)
        )
    }

}
