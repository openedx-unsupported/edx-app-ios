//
//  DiscussionAPI.swift
//  edX
//
//  Created by Tang, Jeff on 6/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


public class DiscussionAPI {
    static func createNewThread(json: JSON) -> NetworkRequest<DiscussionThread> {
        return NetworkRequest(
            method : HTTPMethod.POST,
            path : "/api/discussion/v1/threads/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : {(response, data) -> Result<DiscussionThread> in
                return Result(jsonData : data, error : NSError.oex_unknownError()) {
                    return DiscussionThread(json: $0)
                }
        })
    }
    
    static func createNewComment(json: JSON) -> NetworkRequest<DiscussionComment> {
        return NetworkRequest(
            method : HTTPMethod.POST,
            path : "/api/discussion/v1/comments/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : {(response, data) -> Result<DiscussionComment> in
                return Result(jsonData : data, error : NSError.oex_unknownError()) {
                    return DiscussionComment(json: $0)
                }
        })
    }
    
    static func getThreads(courseID: String) -> NetworkRequest<[DiscussionThread]> {
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: ["course_id" : JSON(courseID), "following": true],
            requiresAuth : true,
            deserializer : {(response, data) -> Result<[DiscussionThread]> in
                return Result(jsonData : data, error : NSError.oex_unknownError(), constructor: {
                    var result: [DiscussionThread] = []
                    if let threads = $0["results"].array {
                        for json in threads {
                            if let discussionThread = DiscussionThread(json: json) {
                                result.append(discussionThread)
                            }
                        }
                    }
                    return result
                })
        })
    }
    
    static func getResponses(threadID: String) -> NetworkRequest<[DiscussionComment]> {
        return NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/comments/", // responses are treated similarly as comments
            query: ["page_size" : 20, "thread_id": JSON(threadID)],
            requiresAuth : true,
            deserializer : {(response, data) -> Result<[DiscussionComment]> in
                return Result(jsonData : data, error : NSError.oex_unknownError()) {                    
                    var result: [DiscussionComment] = []
                    if let threads = $0["results"].array {
                        for json in threads {
                            if let discussionComment = DiscussionComment(json: json) {
                                result.append(discussionComment)
                            }
                        }
                    }
                    return result
                }
        })
    }
    
    static func getCourseTopics(courseID: String) -> NetworkRequest<[DiscussionTopic]> {
        return NetworkRequest(
                method : HTTPMethod.GET,
                path : "/api/discussion/v1/course_topics/\(courseID)",
                requiresAuth : true,
                deserializer : {(response, data) -> Result<[DiscussionTopic]> in
                    return Result(jsonData : data, error : NSError.oex_unknownError()) {
                        var result: [DiscussionTopic] = []
                        let topics = ["courseware_topics", "non_courseware_topics"]
                        for topic in topics {
                            if let results = $0[topic].array {
                                for json in results {
                                    if let topic = DiscussionTopic(json: json) {
                                        result.append(topic)
                                    }
                                }
                            }
                        }
                        return result
                    }
            })
    }

}