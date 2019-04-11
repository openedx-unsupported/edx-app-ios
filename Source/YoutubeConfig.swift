//
//  YoutubeConfig.swift
//  edX
//
//  Created by Andrey Cañon on 14/9/168.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

fileprivate enum YoutubeKeys: String, RawStringExtractable {
    case Enabled = "ENABLED"
    case YoutubeApiKey = "YOUTUBE_API_KEY"
}

class YoutubeVideoConfig: NSObject {
    @objc var enabled: Bool = false
    var youtubeApiKey: String = ""

    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[YoutubeKeys.Enabled] as? Bool ?? false
        youtubeApiKey = dictionary[YoutubeKeys.YoutubeApiKey] as? String ?? ""

    }
}
private let key = "YOUTUBE_VIDEO"
extension OEXConfig {
    @objc var youtubeVideoConfig: YoutubeVideoConfig {
        return YoutubeVideoConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
