//
//  DiscussionDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 7/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class DiscussionDataManager : NSObject {
    private let topicStream = BackedStream<[DiscussionTopic]>()
    private let courseID : String
    private let networkManager : NetworkManager?
    
    public init(courseID : String, networkManager : NetworkManager?) {
        self.courseID = courseID
        self.networkManager = networkManager
    }
    
    public init(courseID : String, topics : [DiscussionTopic]) {
        self.courseID = courseID
        self.networkManager = nil
        self.topicStream.backWithStream(OEXStream(value: topics))
    }
    
    public var topics : OEXStream<[DiscussionTopic]> {
        if topicStream.value == nil && !topicStream.active {
            let request = DiscussionAPI.getCourseTopics(courseID: courseID)
            if let stream = networkManager?.streamForRequest(request, persistResponse: true, autoCancel: false) {
                topicStream.backWithStream(stream)
            }
        }
        return topicStream
    }
    
    /// This signals changes when a response is added
    public let commentAddedStream = Sink<(threadID : String, comment : DiscussionComment)>()
    
    /// This signals changes when a post is read
    public let postReadStream = Sink<(postID : String, read : Bool)>()
    
}
