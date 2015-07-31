//
//  DiscussionTopic+DataFactory.swift
//  edX
//
//  Created by Akiva Leffert on 7/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edX

extension DiscussionTopic {
    static func testTopics() -> [DiscussionTopic] {
        
        return [
            DiscussionTopic(id: nil, name: "Testing", children: [
                DiscussionTopic(id: "DI", name: "Dependency Injection", children: [], depth: 1),
                DiscussionTopic(id: "snapshots", name: "Snapshot Testing", children: [], depth: 1),
                ], depth: 0),
            DiscussionTopic(id: nil, name: "Automation", children: [
                DiscussionTopic(id: "CI", name: "Continuous Integration", children: [], depth: 1),
                ], depth: 0),
            DiscussionTopic(id: "education", name: "Education", children: [], depth: 0)
        ]
    }
    
    static func testTopicIDsLinearized() -> [String?] {
        return [
            nil,
            "DI",
            "snapshots",
            nil,
            "CI",
            "education"
        ]
    }
}