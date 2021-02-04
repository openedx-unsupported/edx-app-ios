//
//  MockResumeCourseProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class MockResumeCourseProvider: ResumeCourseProvider {
   
    private var mockResumeCourseItem: ResumeCourseItem?
    
    public init() { }
    
    public func getResumeCourseBlock(for courseID: String) -> ResumeCourseItem? {
        return mockResumeCourseItem
    }
    
    public func setResumeCourseBlock(with lastVisitedBlockID: String, lastVisitedBlockName: String, courseID: String?, timeStamp: String) {
        mockResumeCourseItem = ResumeCourseItem(lastVisitedBlockID: lastVisitedBlockID, lastVisitedBlockName: lastVisitedBlockName)
    }
    
    public func resetResumeCourseItem() {
        mockResumeCourseItem = nil
    }
}
