//
//  TwitterConfig.swift
//  edX
//
//  Created by Michael Katz on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation


struct TwitterConfiguration {

    fileprivate enum Fields: String, RawStringExtractable {
        case Root = "TWITTER"
        case HashTag = "HASHTAG"
    }

    let hashTag: String?

    init(_ dictionary: NSDictionary) {
        hashTag = dictionary[Fields.HashTag.rawValue] as? String
    }
}

extension OEXConfig {

    var twitterConfiguration: TwitterConfiguration? {
        if let twitterDictionary = self[TwitterConfiguration.Fields.Root] as? NSDictionary {
            return TwitterConfiguration(twitterDictionary)
        }
        return nil
    }
}
