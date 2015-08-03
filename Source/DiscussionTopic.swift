//
//  DiscussionTopic.swift
//  edX
//
//  Created by Akiva Leffert on 7/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


public struct DiscussionTopic {
    public let id: String?
    public let name: String?
    public let children: [DiscussionTopic]
    public let depth : UInt
    
    public init(id: String?, name: String?, children: [DiscussionTopic], depth : UInt = 0) {
        self.id = id
        self.name = name
        self.children = children
        self.depth = depth
    }
    
    init?(json: JSON, depth : UInt = 0) {
        if  let name = json["name"].string {
            self.id = json["id"].string
            self.name = name
            self.depth = depth
            let childJSON = json["children"].array ?? []
            self.children = childJSON.mapSkippingNils {
                return DiscussionTopic(json: $0, depth : depth + 1)
            }
        }
        else {
            return nil
        }
    }
    
    public static func linearizeTopics(topics : [DiscussionTopic]) -> [DiscussionTopic] {
        var result : [DiscussionTopic] = []
        var queue : [DiscussionTopic] = topics.reverse()
        while queue.count > 0 {
            let topic = queue.removeLast()
            result.append(topic)
            queue.extend(topic.children.reverse())
        }
        return result
    }
}
