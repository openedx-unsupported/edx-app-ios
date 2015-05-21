//
//  CourseOutline.swift
//  edX
//
//  Created by Akiva Leffert on 4/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public typealias CourseBlockID = String

public struct CourseOutline {
    public let root : CourseBlockID
    public let blocks : [CourseBlockID:CourseBlock]
    
    init(root : CourseBlockID, blocks : [CourseBlockID:CourseBlock]) {
        self.root = root
        self.blocks = blocks
    }
    
    init?(json : JSON) {
        if let root = json["root"].string, blocks = json["blocks+navigation"].dictionaryObject {
            var validBlocks : [CourseBlockID:CourseBlock] = [:]
            for (blockID, blockBody) in blocks {
                let body = JSON(blockBody)
                let webURL = NSURL(string: body["web_url"].stringValue)
                let children = body["descendants"].arrayObject as? [String] ?? []
                let name = body["display_name"].string ?? ""
                let type : CourseBlockType
                let blockURL = body["block_url"].string.flatMap { NSURL(string:$0) }
                let typeName = body["type"].string ?? ""
                switch typeName ?? "" {
                case "course":
                    type = .Course
                case "chapter":
                    type = .Chapter
                case "sequential":
                    type = .Section
                case "vertical":
                    type = .Unit
                case "html":
                    type = .HTML
                case "problem":
                    type = .Problem
                case "video":
                    let bodyData = body["body_data"].dictionaryObject
                    let summary = OEXVideoSummary(dictionary: bodyData ?? [:])
                    type = .Video(summary)
                default:
                    type = .Unknown(typeName)
                }
                
                validBlocks[blockID] = CourseBlock(
                    type: type,
                    children: children,
                    blockID: blockID,
                    name: name,
                    blockURL : blockURL,
                    webURL: webURL
                )
            }
            self = CourseOutline(root: root, blocks: validBlocks)
        }
        else {
            return nil
        }
    }
}

public enum CourseBlockType : Equatable {
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

public func ==(a: CourseBlockType, b: CourseBlockType) -> Bool
{
    switch(a, b) {
    case (.Unknown, .Unknown):
        return true
    default:
        return false
    }
}

public struct CourseBlock {
    public let type : CourseBlockType
    public let blockID : CourseBlockID
    
    /// Children in the navigation hierarchy.
    /// Note that this may be different than the block's list of children, server side
    /// Since we flatten out the hierarchy for display
    public let children : [CourseBlockID]
    
    /// User visible name of the block.
    public let name : String
    
    /// Just the block content itself as a web page.
    /// Suitable for embedding in a web view.
    public let blockURL : NSURL?
    
    /// A full web page for the block.
    /// Suitable for opening in a web browser.
    public let webURL : NSURL?
    
    public init(type : CourseBlockType, children : [CourseBlockID], blockID : CourseBlockID, name : String, blockURL : NSURL? = nil, webURL : NSURL? = nil) {
        self.type = type
        self.children = children
        self.name = name
        self.blockID = blockID
        self.blockURL = blockURL
        self.webURL = webURL
    }
}

public enum CourseOutlineMode {
    case Full
    case Video
}

