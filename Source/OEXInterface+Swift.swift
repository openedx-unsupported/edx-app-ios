//
//  OEXInterface+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 16/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXInterface: LastAccessedProvider {
    
    public func getLastAccessedBlock(for courseID: String) -> CourseLastAccessed? {
        guard let lastAccessedItem = storage?.lastAccessedData(forCourseID: courseID),
              let blockID = lastAccessedItem.subsection_id,
              let blockName = lastAccessedItem.subsection_name else { return  nil }
        return CourseLastAccessed(lastVisitedBlockID: blockID, lastVisitedBlockName: blockName)
    }
    
    @objc public func setLastAccessedBlock(with lastVisitedBlockID: String, lastVisitedBlockName: String, courseID: String?, timeStamp: String) {
        
        storage?.setLastAccessedSubsection(lastVisitedBlockID, andSubsectionName: lastVisitedBlockName, forCourseID: courseID, onTimeStamp: timeStamp)
    }
    
    public func downloadableVideos(of course: OEXCourse) -> [OEXHelperVideoDownload] {
        // This being O(n) is pretty mediocre
        // We should rebuild this to have all the videos in a hash table
        // Right now they actually need to be in an array since that is
        // how we decide their order in the UI.
        // But once we switch to the new course structure endpoint, that will no longer be the case
        guard let courseVideos = courseVideos,
            let courseID = course.course_id,
            let videos = courseVideos.object(forKey: courseID) as? [OEXHelperVideoDownload] else {
            return []
        }
        
        return videos.filter { $0.summary?.isDownloadableVideo ?? false }
    }
}
