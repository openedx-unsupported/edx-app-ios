//
//  MockLastAccessedProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class MockLastAccessedProvider: LastAccessedProvider {
   
    private var mockLastAccessedItem : CourseLastAccessed?
    
    public init() { }
    
    public func getLastAccessedSectionForCourseID(courseID: String) -> CourseLastAccessed? {
        return self.mockLastAccessedItem
    }
    
    public func setLastAccessedSubSectionWithID(subsectionID: String, subsectionName: String, courseID: String?, timeStamp: String) {
        self.mockLastAccessedItem = CourseLastAccessed(moduleId: subsectionID, moduleName: subsectionName)
    }
    
    public func resetLastAccessedItem() {
        self.mockLastAccessedItem = nil
    }
}
