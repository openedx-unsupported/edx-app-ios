//
//  BulkDownloadHelper.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 18/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

enum BulkDownloadState {
    case new
    case downloading
    case partial
    case downloaded
    case none // if course has no `downloadable` videos.
}

class BulkDownloadHelper {
    
    private(set) var course: OEXCourse
    private let interface: OEXInterface?
    private(set) var state: BulkDownloadState = .new
    var courseVideos: [OEXHelperVideoDownload] {
        return interface?.downloadableVideos(of: course) ?? []
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
    
    var progress: Float {
        return totalSize == 0 ? 0.0 : Float(downloadedSize / totalSize)
    }
    
    init(with course: OEXCourse, interface: OEXInterface?) {
        self.course = course
        self.interface = interface
        refreshState()
    }
    
    func refreshState() {
        state = bulkDownloadState()
    }
    
    private func bulkDownloadState() -> BulkDownloadState {
        if courseVideos.count <= 0 {
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
    
    var roundedMB: Double {
        return mb.roundTo(places: 2)
    }
}
