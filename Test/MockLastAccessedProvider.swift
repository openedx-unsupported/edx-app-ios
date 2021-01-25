//
//  MockLastAccessedProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class MockLastAccessedProvider: LastAccessedProvider {
   
    private var mockLastAccessedItem: CourseLastAccessed?
    
    public init() { }
    
    public func getLastAccessedBlock(for courseID: String) -> CourseLastAccessed? {
        return mockLastAccessedItem
    }
    
    public func setLastAccessedBlock(with lastVisitedBlockID: String, lastVisitedBlockName: String, courseID: String?, timeStamp: String) {
        mockLastAccessedItem = CourseLastAccessed(lastVisitedBlockID: lastVisitedBlockID, lastVisitedBlockName: lastVisitedBlockName)
    }
    
    public func resetLastAccessedItem() {
        mockLastAccessedItem = nil
    }
}
