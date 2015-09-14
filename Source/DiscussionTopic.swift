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
    public let icon : Icon?
    //MA-1247
    /// Will return false for cases when the topic is the root node. However, the constructor can override it
    public let isSelectable : Bool
    
    public init(id: String?, name: String?, children: [DiscussionTopic], depth : UInt = 0, icon : Icon? = nil, forceSelectable : Bool = false) {
        self.id = id
        self.name = name
        self.children = children
        self.depth = depth
        self.icon = icon
        self.isSelectable = forceSelectable ? true : depth != 0
    }
    
    init?(json: JSON, depth : UInt = 0) {
        if  let name = json["name"].string {
            self.id = json["id"].string
            self.name = name
            self.depth = depth
            self.icon =  nil
            let childJSON = json["children"].array ?? []
            self.children = childJSON.mapSkippingNils {
                return DiscussionTopic(json: $0, depth : depth + 1)
            }
            self.isSelectable = depth != 0
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
