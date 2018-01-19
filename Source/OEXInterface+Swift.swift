//
//  OEXInterface+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 16/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXInterface : LastAccessedProvider {
    
    public func getLastAccessedSectionForCourseID(courseID : String) -> CourseLastAccessed? {
        guard  let lastAccessed = storage?.lastAccessedData(forCourseID: courseID) else { return  nil }
        guard let moduleId = lastAccessed.subsection_id, let moduleName = lastAccessed.subsection_name else { return nil }
        return CourseLastAccessed(moduleId: moduleId, moduleName: moduleName)
    }

    public func setLastAccessedSubSectionWithID(subsectionID: String, subsectionName: String, courseID: String?, timeStamp: String) {
        self.storage?.setLastAccessedSubsection(subsectionID, andSubsectionName: subsectionName, forCourseID: courseID, onTimeStamp: timeStamp)
    }
    
    public func downloadableVideos(of course: OEXCourse) -> [OEXHelperVideoDownload] {
        // This being O(n) is pretty mediocre
        // We should rebuild this to have all the videos in a hash table
        // Right now they actually need to be in an array since that is
        // how we decide their order in the UI.
        // But once we switch to the new course structure endpoint, that will no longer be the case
        guard let courseVideos = courseVideos,
            let videoOutline = course.video_outline,
            let videos = courseVideos.object(forKey: videoOutline) as? [OEXHelperVideoDownload] else {
            return []
        }
        
        return videos.filter { $0.summary?.isDownloadableVideo ?? false }
    }
    
}
