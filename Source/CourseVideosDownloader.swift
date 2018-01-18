//
//  CourseVideosDownloader.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 18/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

class CourseVideosDownloader {
    
    let course: OEXCourse
    init(with course: OEXCourse) {
        self.course = course
    }
    
    var courseVideos: [OEXHelperVideoDownload] {
        return OEXInterface.shared().videos(of: self.course)
    }
    
    var newVideos: [OEXHelperVideoDownload] {
        return courseVideos.filter { $0.downloadState == .new }
    }
    
    var partialyDownloadedVideos: [OEXHelperVideoDownload] {
        return courseVideos.filter { $0.downloadState == .partial }
    }
    
    var fullyDownloadedVideos: [OEXHelperVideoDownload] {
        return courseVideos.filter { $0.downloadState == .complete }
    }
    
    var partialyOrFullyDownloadedVideos: [OEXHelperVideoDownload] {
        return courseVideos.filter { $0.downloadState != .new }
    }
    
    var newOrPartiallyDownloadedVideos: [OEXHelperVideoDownload] {
        return courseVideos.filter { $0.downloadState != .complete }
    }
    
    var totalSize: Double {
        return courseVideos.reduce(into: 0.0) { (sum, video) in sum = sum + Double(video.summary?.size ?? 0) }
    }
    
    var downloadedSize: Double {
        return courseVideos.reduce(into: 0.0) { (sum, video) in
            sum = sum + ((video.downloadProgress *  Double(video.summary?.size ?? 0.0)) / 100.0)
        }
    }
    
    var remainingSize: Double {
        return totalSize - downloadedSize
    }
    
    var fullyDownloadedVideosSize : Double {
        return fullyDownloadedVideos.reduce(into: 0.0) { (sum, video) in sum = sum + Double(video.summary?.size ?? 0) }
    }
    
    var isDownloadingAllVideos: Bool {
        return (courseVideos.filter { $0.downloadState == .new }).count == 0
    }
    
    var isDownloadedAllVideos: Bool {
        return fullyDownloadedVideos.count == courseVideos.count
    }
    
    var isDownloadedAnyVideo: Bool {
        return fullyDownloadedVideos.count > 0
    }
    
    var isDownloadingAnyVideo: Bool {
        return partialyDownloadedVideos.count > 0
    }
    
}
