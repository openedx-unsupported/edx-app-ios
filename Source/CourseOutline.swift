//
//  CourseOutline.swift
//  edX
//
//  Created by Akiva Leffert on 4/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

// TODO: Update to match final course structure API

public typealias CourseBlockID = String

public struct CourseOutline {
    public let root : CourseBlockID
    public let blocks : [CourseBlockID:CourseBlock]
}

public enum CourseBlockType {
    case Unknown(String)
    case Course
    case Chapter
    case Section
    case Unit
    case Video(OEXVideoSummary)
    case Problem
    case HTML
    
    public var asVideo : OEXVideoSummary? {
        switch self {
        case let .Video(summary):
            return summary
        default:
            return nil
        }
    }
}

public struct CourseBlock {
    public let type : CourseBlockType
    public let children : [CourseBlockID]
    public let blockID : CourseBlockID
    public let name : String
    public let webURL : NSURL?
    
    public init(type : CourseBlockType, children : [CourseBlockID], blockID : CourseBlockID, name : String, webURL : NSURL? = nil) {
        self.type = type
        self.children = children
        self.name = name
        self.blockID = blockID
        self.webURL = webURL
    }
}

public enum CourseOutlineMode {
    case Full
    case Video
}

