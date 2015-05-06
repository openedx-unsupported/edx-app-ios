//
//  CourseBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


@objc protocol CourseBlockViewController : class {
    var blockID : CourseBlockID {get}
}