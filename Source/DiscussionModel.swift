//
//  DiscussionModel.swift
//  edX
//
//  Created by Saeed Bashir on 5/26/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public class DiscussionModel: NSObject {
    let topicID: String?
    public init(dictionary: NSDictionary) {
        topicID = dictionary["topic_id"] as? String
    }
}