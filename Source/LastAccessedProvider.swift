//
//  LastAccessedProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol LastAccessedProvider: class {
    func getLastAccessedSectionForCourseID(courseID : String) -> CourseLastAccessed?
    func setLastAccessedSubSectionWithID(subsectionID: String, subsectionName: String, courseID: String?, timeStamp: String)
}
