//
//  OEXInterface+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 16/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXInterface {
    
    func getLastAccessedSectionForCourseID(courseID : String) -> CourseLastAccessed? {
        if let lastAccessed = storage?.lastAccessedDataForCourseID(courseID) {
            let lastAccessedSection = CourseLastAccessed(moduleId: lastAccessed.subsection_id, moduleName: lastAccessed.subsection_name)
            return lastAccessedSection
        }
        return nil
    }
}