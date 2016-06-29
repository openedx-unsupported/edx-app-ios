//
//  LocalStorageInterface.swift
//  edX
//
//  Created by Michael Katz on 6/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

//TODO: split the implementation of these into two different providers
@objc protocol CourseInfoStorageInterface: class {
    func lastAccessedData(courseId: String) -> LastAccessed?
    func setLastAccessedSubsection(subsectionID: String, subsectionName: String, courseID: String, timestamp: String)
    func deactivate()
}

@objc protocol VideoStorageInterface: class {
    func lastPlayedInterval(videoId: String) -> Float
    func markLastPlayedInterval(videoId: String, interval: Float)
    func markPlayedState(videoId: String, state: OEXPlayedState)
    func deleteVideoData(videoId: String)
    func registerAllVideos(forEnrollments courses:Set<String>)
    func deleteUnregisteredVideos()
    func insertVideoData(
        username: String?,
        title: String?,
        size: String?,
        duration: String?,
        downloadState: OEXDownloadState,
        videoUrl: String?,
        videoId: String,
        unitURL: String?,
        courseId: String?,
        dmId: Int,
        chapterName: String?,
        sectionName: String?,
        downloadTimestamp: NSDate?,
        lastPlayedTime: Float,
        isRegistered: Bool,
        playedState: OEXPlayedState
        ) -> VideoData
    func videoDownloadComplete(data: VideoData?)
    func videoDownloadCancelled(data: VideoData?)
    func videosForTaskIdentifier(taskId: Int) -> [VideoData]?
    func videosForDownloadState(state: OEXDownloadState) -> [VideoData]?
    func pausedAllDownloads()
    func allCurrentlyDownloadingVideos(url: String) -> [VideoData]?
}
