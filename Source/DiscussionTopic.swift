//
//  DiscussionTopic.swift
//  edX
//
//  Created by Akiva Leffert on 7/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


struct DiscussionTopic {
    var id: String?
    var name: String?
    var children: [DiscussionTopic]?
    
    init(id: String?, name: String?, children: [DiscussionTopic]?) {
        self.id = id
        self.name = name
        self.children = children
    }
    
    init?(json: JSON) {
        if  let name = json["name"].string {
            if let children = json["children"].array {
                self.id = json["id"].string
                self.name = name
                
                if children.count > 0 {
                    var resultChild: [DiscussionTopic] = []
                    for child in children {
                        if  let name = child["name"].string {
                            resultChild.append(DiscussionTopic(id: child["id"].string, name: name, children: nil))
                        }
                    }
                    self.children = resultChild
                }
                else {
                    self.children = nil
                }
            }
        }
        else {
            return nil
        }
    }
}
