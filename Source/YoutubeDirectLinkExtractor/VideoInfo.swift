//
//  VideoInfo.swift
//  YoutubeDirectLinkExtractor
//
//  Created by Andrey Sevrikov on 05/03/2018.
//  Copyright © 2018 Andrey Sevrikov. All rights reserved.
//

import Foundation
import AVFoundation

public struct VideoInfo {
    
    /** Raw info for each video quality. Elements are sorted by video quality with first being the highest quality. */
    public let rawInfo: [[String: String]]
    
    public var highestQualityPlayableLink: String? {
        let urls = rawInfo.compactMap { $0["url"] }
        return firstPlayable(from: urls)
    }
    
    public var lowestQualityPlayableLink: String? {
        let urls = rawInfo.reversed().compactMap { $0["url"] }
        return firstPlayable(from: urls)
    }
    
    private func firstPlayable(from urls: [String]) -> String? {
        for urlString in urls {
            guard let url = URL(string: urlString) else {
                continue
            }
            let asset = AVAsset(url: url)
            if asset.isPlayable {
                return urlString
            }
        }
        
        return nil
    }
}
