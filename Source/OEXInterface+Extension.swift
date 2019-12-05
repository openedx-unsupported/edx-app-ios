//
//  OEXInterface+Extension.swift
//  edX
//
//  Created by Muhammad Umer on 12/5/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation

extension OEXInterface {
    func insertVideoDataIfNotExists(_ video: OEXHelperVideoDownload) {
        guard let videoId = video.summary?.videoID else { return }
        let data = storage?.videoData(forVideoID: videoId)
        if data == nil {
            insertVideoData(video)
        }
    }
}
