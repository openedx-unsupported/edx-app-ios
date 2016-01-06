//
//  TwitterConfig.swift
//  edX
//
//  Created by Michael Katz on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation


struct TwitterConfiguration {

    private enum Fields: String {
        case HashTag = "HASHTAG"
    }

    let hashTag: String?

    init(_ dictionary: NSDictionary) {
        hashTag = dictionary[Fields.HashTag.rawValue] as? String
    }
}