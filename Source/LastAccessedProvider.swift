//
//  LastAccessedProvider.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol LastAccessedProvider: class {
    func getLastAccessedBlock(for courseID: String) -> CourseLastAccessed?
    func setLastAccessedBlock(with lastVisitedBlockID: String, lastVisitedBlockName: String, courseID: String?, timeStamp: String)
}
