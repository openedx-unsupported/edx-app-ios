//
//  CourseVideosDownloader.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 18/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

class CourseVideosHelper {
    
    let course: OEXCourse
    var newVideos: [OEXHelperVideoDownload] = []
    var partialyOrFullyDownloadedVideos: [OEXHelperVideoDownload] = []
    var courseVideos: [OEXHelperVideoDownload] = []
    private var partialyDownloadedVideos: [OEXHelperVideoDownload]  = []
    private var fullyDownloadedVideos: [OEXHelperVideoDownload] = []
    private var newOrPartiallyDownloadedVideos: [OEXHelperVideoDownload] = []
    private var totalSize: Double = 0
    private var downloadedSize: Double = 0
    private var fullyDownloadedVideosSize : Double = 0
    
    init(with course: OEXCourse) {
        self.course = course
        refresh()
    }
    
    func refresh() {
        
        courseVideos = OEXInterface.shared().downloadableVideos(of: course)
        newVideos = courseVideos.filter { $0.downloadState == .new }
        partialyDownloadedVideos = courseVideos.filter { $0.downloadState == .partial }
        fullyDownloadedVideos = courseVideos.filter { $0.downloadState == .complete }
        partialyOrFullyDownloadedVideos = courseVideos.filter { $0.downloadState != .new }
        newOrPartiallyDownloadedVideos = courseVideos.filter { $0.downloadState != .complete }
        
        // Calculate Sizes
        totalSize = courseVideos.reduce(into: 0.0) {
            (sum, video) in
            sum = sum + Double(video.summary?.size ?? 0)
        }
        downloadedSize = courseVideos.reduce(into: 0.0) {
            (sum, video) in
            sum = sum + ((video.downloadProgress *  Double(video.summary?.size ?? 0.0)) / 100.0)
        }
        fullyDownloadedVideosSize = fullyDownloadedVideos.reduce(into: 0.0) {
            (sum, video) in
            sum = sum + Double(video.summary?.size ?? 0)
        }
    }
    
    private var remainingSize: Double {
        return totalSize - downloadedSize
    }
    
    var toggleOn: Bool {
        return isDownloadingAllVideos
    }
    
    var hideProgressBar: Bool {
        return !(toggleOn && !isDownloadedAllVideos)
    }
    
    var hideSpinner: Bool {
        return hideProgressBar
    }
    
    var title: String {
        if isDownloadedAllVideos {
            return Strings.allVideosDownloadedTitle
        }
        else if isDownloadingAllVideos {
            return Strings.downloadingVideosTitle
        }
        return Strings.downloadToDeviceTitle
    }
    
    var subTitle: String {
        if !isDownloadedAllVideos && (isDownloadingAllVideos || isDownloadedAnyVideo || isDownloadingAnyVideo) {
            return Strings.downloadingVideosSubTitle(remainingVideosCount: "\(newOrPartiallyDownloadedVideos.count)", remainingVideosSize: "\(videosSizeForStatus)")
        }
        return Strings.allVideosSubTitle(videosCount: "\(courseVideos.count)", videosSize: "\(videosSizeForStatus)")
    }
    
    var progress: Float {
       return Float(downloadedSize / totalSize)
    }
    
    private var videosSizeForStatus: Double {
        if !isDownloadedAllVideos {
            if isDownloadingAllVideos {
                return remainingSize.roundedMB
            }
            else if isDownloadedAnyVideo || isDownloadingAnyVideo {
                let remainingSize = totalSize - fullyDownloadedVideosSize
                return remainingSize.roundedMB
            }
        }
        return totalSize.roundedMB
    }
    
    private var isDownloadingAllVideos: Bool {
        return newVideos.count == 0
    }
    
    var isDownloadedAllVideos: Bool {
        return fullyDownloadedVideos.count == courseVideos.count
    }
    
    private var isDownloadedAnyVideo: Bool {
        return fullyDownloadedVideos.count > 0
    }
    
    private var isDownloadingAnyVideo: Bool {
        return partialyDownloadedVideos.count > 0
    }
}

extension Double {
    // Bytes to MB Conversion
    private var mb: Double {
        return self / 1024 / 1024
    }
    
    private func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    fileprivate var roundedMB: Double {
        return self.mb.roundTo(places: 2)
    }
}
