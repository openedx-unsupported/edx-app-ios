//
//  OEXCourse+Swift.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension OEXCourse {
    
    var hasDiscussionsEnabled : Bool {
        return self.discussionUrl != nil
    }
}