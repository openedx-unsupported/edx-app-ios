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
        let lastAccessed : LastAccessed? = storage.lastAccessedDataForCourseID(courseID)
        if let dbLastAccessedSection = lastAccessed {
            let lastAccessedSection = CourseLastAccessed(moduleId: dbLastAccessedSection.subsection_id, moduleName: dbLastAccessedSection.subsection_name)
            return lastAccessedSection
        }
        return nil
    }
}