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
        if let lastAccessed = storage?.lastAccessedDataForCourseID(courseID) {
            let lastAccessedSection = CourseLastAccessed(moduleId: lastAccessed.subsection_id, moduleName: lastAccessed.subsection_name)
            return lastAccessedSection
        }
        return nil
    }

    public func setLastAccessedSubSectionWithID(subsectionID: String, subsectionName: String, courseID: String?, timeStamp: String) {
        self.storage?.setLastAccessedSubsection(subsectionID, andSubsectionName: subsectionName, forCourseID: courseID, onTimeStamp: timeStamp)
    }

    public func courseStreamWithID(courseID : String) -> Stream<OEXCourse> {
        if let course = self.courseWithID(courseID) {
            return Stream(value: course)
        }
        else {
            return Stream(error: NSError.oex_unknownError())
        }
    }
}