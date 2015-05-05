//
//  CourseOutline.swift
//  edX
//
//  Created by Akiva Leffert on 4/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

// TODO: Update to match final course structure API

typealias CourseBlockID = String

struct CourseOutline {
    let root : CourseBlockID
    let blocks : [CourseBlockID:CourseBlock]
}

@objc enum CourseBlockType : UInt {
    case Unknown
    case Course
    case Chapter
    case Section
    case Unit
    case Video
    case Problem
    case HTML
}

struct CourseBlock {
    let type : CourseBlockType
    let children : [CourseBlockID]
    let blockID : CourseBlockID
    let name : String
    let webURL : NSURL?
    let typeName : String?
    
    init(type : CourseBlockType, children : [CourseBlockID], blockID : CourseBlockID, name : String, webURL : NSURL? = nil, typeName : String? = nil) {
        self.type = type
        self.children = children
        self.name = name
        self.blockID = blockID
        self.webURL = webURL
        self.typeName = typeName
    }
}

enum CourseOutlineMode {
    case Full
    case Video
}

