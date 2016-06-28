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


private enum Entities : String {
    case LastAccessed = "LastAccessed"
    case VideoData = "VideoData"

    func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName(self.rawValue, inManagedObjectContext: context)!
    }

    func fetchRequest(context: NSManagedObjectContext) -> NSFetchRequest {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity(context)
        return fetchRequest
    }
}

//TODO: continue moving functionality out of OEXInterface that is video state specific

@objc class CoreDataStorage : NSObject, CourseInfoStorageInterface, VideoStorageInterface {

    //MARK: - Setup

    let context: NSManagedObjectContext

    override init() {
        let model = NSManagedObjectModel.mergedModelFromBundles(nil)!

        let storePath = (OEXFileUtility.userDirectory()! as NSString).stringByAppendingPathComponent("Database/edXDB.sqlite")
        let storeURL = NSURL(fileURLWithPath: storePath)
        Logger.logInfo("STORAGE", "DB path \(storeURL)")

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch {
            Logger.logError("STORAGE", "unresolved error \(error)")
        }

        context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
    }

    func save() {
        do {
            try context.save()
        } catch {
            Logger.logError("STORAGE", "Could not save changes to database \(error)")
        }
    }

    func deactivate() {
        Logger.logInfo("STORAGE", "Deactivating database")
        save()
        context.reset()
    }

    //MARK: - Last Accessed

    func lastAccessedData(courseId: String) -> LastAccessed? {
        let fetchRequest = Entities.LastAccessed.fetchRequest(context)

        let query = NSPredicate(format: "course_id==%@", courseId)
        fetchRequest.predicate = query

        let result = try? context.executeFetchRequest(fetchRequest) as? [LastAccessed]

        return result?.flatMap { return $0.first }
    }

    func setLastAccessedSubsection(subsectionID: String, subsectionName: String, courseID: String, timestamp: String) {
        var last = lastAccessedData(courseID)
        if last == nil {
            last = NSEntityDescription.insertNewObjectForEntityForName(Entities.LastAccessed.rawValue, inManagedObjectContext: context) as? LastAccessed
            last?.course_id = courseID
        }
        last?.subsection_id = subsectionID
        last?.subsection_name = subsectionName
        last?.timestamp = timestamp
        save()
    }

    //MARK: - Videos

    func allVideos() -> [VideoData]? {
        let fetchRequest = Entities.VideoData.fetchRequest(context)
        let result = try? context.executeFetchRequest(fetchRequest) as? [VideoData]
        return result?.flatMap { return $0 }
    }

    func videoData(videoId: String) -> VideoData? {
        let fetchRequest = Entities.VideoData.fetchRequest(context)

        let query = NSPredicate(format: "video_id==%@", videoId)
        fetchRequest.predicate = query

        let result = try? context.executeFetchRequest(fetchRequest) as? [VideoData]
        return result?.flatMap { return $0.first }
    }

    func videosDownloadsForUrl(downloadURL: String) -> [VideoData]? {
        let fetchRequest = Entities.VideoData.fetchRequest(context)

        let query = NSPredicate(format: "video_url==%@", downloadURL)
        fetchRequest.predicate = query

        let result = try? context.executeFetchRequest(fetchRequest) as? [VideoData]
        return result?.flatMap { return $0 }
    }

    func lastPlayedInterval(videoId: String) -> Float {
        guard let videoData = videoData(videoId) else { return 0 }
        return videoData.last_played_offset.floatValue
    }

    func markLastPlayedInterval(videoId: String, interval: Float) {
        guard let videoData = videoData(videoId) else { return }
        videoData.last_played_offset = interval
        save()
    }

    func markPlayedState(videoId: String, state: OEXPlayedState) {
        guard let videoData = videoData(videoId) else { return }
        videoData.played_state = state.rawValue
        save()
    }

    func deleteVideoData(videoId: String) {
        guard let videoData = videoData(videoId), videoURL = videoData.video_url else { return }
        var referenceCount = 0
        if let videos = videosDownloadsForUrl(videoURL) where videos.count > 1 {
            for video in videos {
                if video.download_state.integerValue == OEXDownloadState.Complete.rawValue {
                    referenceCount += 1
                }
            }
        }

        //Mark new in DB
        videoData.download_state = OEXDownloadState.New.rawValue
        videoData.dm_id = 0
        save()

        if (referenceCount <= 1) {
            FileSystemProvider.deleteVideoFile(videoURL)
        }

    }

    func registerAllVideos(forEnrollments courses:Set<String>) {
        guard let videos = allVideos() else { return }

        for video in videos {
            if video.enrollment_id != nil && courses.contains(video.enrollment_id!) {
                video.is_registered = true
            }
        }
        save()
    }

    func deleteUnregisteredVideos() {
        let fetchRequest = Entities.VideoData.fetchRequest(context)
        fetchRequest.predicate = NSPredicate(format: "is_registered==%@", false)

        if let videos = (try? context.executeFetchRequest(fetchRequest)) as? [VideoData] {
            for video in videos {
                if let url = video.video_url {
                    FileSystemProvider.deleteVideoFile(url)
                }
                context.deleteObject(video)
            }
            save()
        }
    }

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
        ) -> VideoData {
        var data: VideoData! = videoData(videoId)

        if data == nil {
            data = NSEntityDescription.insertNewObjectForEntityForName(Entities.VideoData.rawValue, inManagedObjectContext: context) as? VideoData
        }

        data?.username = username
        data?.title = title
        data?.size = size
        data?.duration = duration
        data?.download_state = downloadState.rawValue
        data?.video_url = videoUrl
        data?.video_id = videoId
        data?.unit_url = unitURL
        data?.enrollment_id = courseId
        data?.dm_id = dmId
        data?.chapter_name = chapterName
        data?.section_name = sectionName
        data?.downloadCompleteDate = downloadTimestamp
        data?.last_played_offset = lastPlayedTime
        data?.is_registered = isRegistered
        data?.played_state = playedState.rawValue

        save()
        return data
    }

    func videoDownloadComplete(data: VideoData?) {
        guard let data = data else { return }
        data.download_state = OEXDownloadState.Complete.rawValue
        data.downloadCompleteDate = NSDate()
        data.dm_id = 0
        save()
    }

    func videoDownloadCancelled(data: VideoData?) {
        guard let data = data else { return }
        data.download_state = OEXDownloadState.New.rawValue
        data.dm_id = 0
        deleteVideoData(data.video_id!)
        save()
    }

    func videosForTaskIdentifier(taskId: Int) -> [VideoData]? {
        let fetchRequest = Entities.VideoData.fetchRequest(context)

        let query = NSPredicate(format: "dm_id==%lu", taskId)
        fetchRequest.predicate = query

        let result = try? context.executeFetchRequest(fetchRequest) as? [VideoData]
        return result?.flatMap { return $0 }
    }

    func videosForDownloadState(state: OEXDownloadState) -> [VideoData]? {
        guard let videos = allVideos() else { return nil }
        return videos.filter { $0.download_state == state.rawValue }
    }

    func pausedAllDownloads() {
        guard let videos = allVideos() else { return }
        for video in videos {
            if video.download_state == OEXDownloadState.Partial.rawValue || video.dm_id != 0 {
                video.dm_id = 0
            }
        }
        save()
    }

    func allCurrentlyDownloadingVideos(url: String) -> [VideoData]? {
        guard let videos = videosDownloadsForUrl(url) else { return nil }
        return videos.filter { $0.download_state == OEXDownloadState.Partial.rawValue  || $0.dm_id != 0}
    }
}
