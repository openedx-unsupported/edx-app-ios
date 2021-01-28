//
//  ResumeCourseProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol ResumeCourseProvider: class {
    func getResumeCourseBlock(for courseID: String) -> ResumeCourse?
    func setResumeCourseBlock(with lastVisitedBlockID: String, lastVisitedBlockName: String, courseID: String?, timeStamp: String)
}
