//
//  LocalStorageInterface.swift
//  edX
//
//  Created by Michael Katz on 6/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

@objc protocol CourseInfoStorageInterface: class {
    func lastAccessedData(courseId: String) -> LastAccessed?
    func setLastAccessedSubsection(subsectionID: String, subsectionName: String, courseID: String, timestamp: String)
}

@objc protocol VideoStorageInterface: class {
    func lastPlayedInterval(videoId: String) -> Float
    func markLastPlayedInterval(videoId: String, interval: Float)
    func deleteVideoData(videoId: String)
}


private enum Entities : String {
    case LastAccessed = "LastAccessed"
    case VideoData = "VideoData"

    func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName(self.rawValue, inManagedObjectContext: context)!
    }
}

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

    //MARK: - Last Accessed

    func lastAccessedData(courseId: String) -> LastAccessed? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Entities.LastAccessed.entity(context)

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

    func videoData(videoId: String) -> VideoData? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Entities.VideoData.entity(context)

        let query = NSPredicate(format: "video_id==%@", videoId)
        fetchRequest.predicate = query

        let result = try? context.executeFetchRequest(fetchRequest) as? [VideoData]
        return result?.flatMap { return $0.first }
    }

    func videoDownloadsForUrl(downloadURL: String) -> [VideoData]? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Entities.VideoData.entity(context)

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

    func deleteVideoData(videoId: String) {
        guard let videoData = videoData(videoId) else { return }
        var referenceCount = 0
        if let videos = videoDownloadsForUrl(videoData.video_url) where videos.count > 1 {
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
            FileSystemProvider.deleteVideoFile(videoData.video_url)
        }

    }
}

