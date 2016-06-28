//
//  OEXInterface+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 16/06/2015.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

import Foundation

extension OEXInterface : LastAccessedProvider {
    
    public func getLastAccessedSectionForCourseID(courseID : String) -> CourseLastAccessed? {
        guard  let lastAccessed = storage?.lastAccessedData(courseID) else { return  nil }
        guard let moduleId = lastAccessed.subsection_id, moduleName = lastAccessed.subsection_name else { return nil }
        return CourseLastAccessed(moduleId: moduleId, moduleName: moduleName)
    }

    public func setLastAccessedSubSectionWithID(subsectionID: String, subsectionName: String, courseID: String, timeStamp: String) {
        self.storage?.setLastAccessedSubsection(subsectionID, subsectionName: subsectionName, courseID: courseID, timestamp: timeStamp)
    }
}