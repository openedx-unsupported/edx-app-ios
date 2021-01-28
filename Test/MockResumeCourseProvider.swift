//
//  MockResumeCourseProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class MockResumeCourseProvider: ResumeCourseProvider {
   
    private var mockResumeCourseItem: ResumeCourse?
    
    public init() { }
    
    public func getResumeCourseBlock(for courseID: String) -> ResumeCourse? {
        return mockResumeCourseItem
    }
    
    public func setResumeCourseBlock(with lastVisitedBlockID: String, lastVisitedBlockName: String, courseID: String?, timeStamp: String) {
        mockResumeCourseItem = ResumeCourse(lastVisitedBlockID: lastVisitedBlockID, lastVisitedBlockName: lastVisitedBlockName)
    }
    
    public func resetResumeCourseItem() {
        mockResumeCourseItem = nil
    }
}
