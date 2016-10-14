//
//  CourseOutlineMode.swift
//  edX
//
//  Created by Akiva Leffert on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public enum CourseOutlineMode : String {
    case Full = "full"
    case Video = "video"
    
    public var isVideo : Bool {
        switch self {
        case .Video:
            return true
        default:
            return false
        }
    }
}