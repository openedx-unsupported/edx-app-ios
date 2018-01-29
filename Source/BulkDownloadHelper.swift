//
//  BulkDownloadHelper.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 18/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

enum BulkDownloadState {
    case new // All videos are in new state.
    case downloading // All videos are downloading
    case partial // Some Videos downloading in progress or completed
    case downloaded // All Videos downloading completed.
    case none // If Course has no Video
}

class BulkDownloadHelper {
    
    let course: OEXCourse
    var state: BulkDownloadState = .none
    var courseVideos: [OEXHelperVideoDownload] {
        return OEXInterface.shared().downloadableVideos(of: course)
    }
    
    var newVideosCount: Int {
        return (courseVideos.filter { $0.downloadState == .new }).count
    }
    var partialAndNewVideosCount: Int {
        return (courseVideos.filter { $0.downloadState == .partial || $0.downloadState == .new }).count
    }
    
    var totalSize: Double {
        return courseVideos.reduce(into: 0.0) {
            (sum, video) in
            sum = sum + Double(video.summary?.size ?? 0)
        }
    }
    var downloadedSize: Double {
        switch state {
        case .downloaded:
            return totalSize
        case .downloading:
            return courseVideos.reduce(into: 0.0) {
                (sum, video) in
                sum = sum + ((video.downloadProgress *  Double(video.summary?.size ?? 0.0)) / 100.0)
            }
        case .partial:
            let fullyDownloadedVideos = courseVideos.filter { $0.downloadState == .complete }
            return fullyDownloadedVideos.reduce(into: 0.0) {
                (sum, video) in
                sum = sum + Double(video.summary?.size ?? 0)
            }
        default:
            return 0.0
        }
    }
    
    var videoSizeForStatus: Double {
        return (state == .downloaded ? totalSize : totalSize - downloadedSize).roundedMB
    }
    
    var progress: Float {
        return totalSize == 0 ? 0.0 : Float(downloadedSize / totalSize)
    }
    
    init(with course: OEXCourse) {
        self.course = course
        refreshState()
    }
    
    func refreshState() {
        state = bulkDownloadState()
    }
    
    private func bulkDownloadState() -> BulkDownloadState {
        guard courseVideos.count != 0 else {
            return .none
        }
        let allNew = courseVideos.reduce(true) {(acc, video) in
            return acc && video.downloadState == .new
        }
        
        if allNew {
            return .new
        }
        
        let allCompleted = courseVideos.reduce(true) {(acc, video) in
            return acc && video.downloadState == .complete
        }
        if allCompleted {
            return .downloaded
        }
        
        let allPartialyOrFullyDownloaded = courseVideos.reduce(true) {(acc, video) in
            return acc && video.downloadState != .new
        }
        if allPartialyOrFullyDownloaded {
            return .downloading
        }
        
        return .partial
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
