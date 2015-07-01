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
    
    public init(root : CourseBlockID, blocks : [CourseBlockID:CourseBlock]) {
        self.root = root
        self.blocks = blocks
    }
    
    public init?(json : JSON) {
        if let root = json["root"].string, blocks = json["blocks+navigation"].dictionaryObject {
            var validBlocks : [CourseBlockID:CourseBlock] = [:]
            for (blockID, blockBody) in blocks {
                let body = JSON(blockBody)
                let webURL = NSURL(string: body["web_url"].stringValue)
                let children = body["descendants"].arrayObject as? [String] ?? []
                let name = body["display_name"].string ?? ""
                let blockURL = body["block_url"].string.flatMap { NSURL(string:$0) }
                let format = body["format"].string
                let type : CourseBlockType
                let typeName = body["type"].string ?? ""
                let isResponsive = body["responsive_ui"].bool ?? true
                let blockCounts = (body["block_count"].dictionaryObject as? [String:NSNumber] ?? [:]).mapValues {
                    $0.integerValue
                }
                let graded = body["graded"].bool ?? false
                if let category = CourseBlock.Category(rawValue: typeName) {
                    switch category {
                    case CourseBlock.Category.Course:
                        type = .Course
                    case CourseBlock.Category.Chapter:
                        type = .Chapter
                    case CourseBlock.Category.Section:
                        type = .Section
                    case CourseBlock.Category.Unit:
                        type = .Unit
                    case CourseBlock.Category.HTML:
                        type = .HTML
                    case CourseBlock.Category.Problem:
                        type = .Problem
                    case CourseBlock.Category.Video :
                        let bodyData = body["block_json"].dictionaryObject.map { ["summary" : $0 ] }
                        let summary = OEXVideoSummary(dictionary: bodyData ?? [:], videoID: blockID, name : name)
                        type = .Video(summary)
                    }
                }
                else {
                    type = .Unknown(typeName)
                }
                
                validBlocks[blockID] = CourseBlock(
                    type: type,
                    children: children,
                    blockID: blockID,
                    name: name,
                    blockCounts : blockCounts,
                    blockURL : blockURL,
                    webURL: webURL,
                    format : format,
                    isResponsive : isResponsive,
                    graded : graded
                )
            }
            self = CourseOutline(root: root, blocks: validBlocks)
        }
        else {
            return nil
        }
    }
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
    
    /// Simple list of known block categories strings
    public enum Category : String {
        case Chapter = "chapter"
        case Course = "course"
        case HTML = "html"
        case Problem = "problem"
        case Section = "sequential"
        case Unit = "vertical"
        case Video = "video"
    }
    
    public let type : CourseBlockType
    public let blockID : CourseBlockID
    
    /// Children in the navigation hierarchy.
    /// Note that this may be different than the block's list of children, server side
    /// Since we flatten out the hierarchy for display
    public let children : [CourseBlockID]
    
    /// User visible name of the block.
    public let name : String
    
    /// TODO: Match final API name
    /// The type of graded component
    public let format : String?
    
    /// Mapping between block types and number of blocks of that type in this block's
    /// descendants (recursively) for example ["video" : 3]
    public let blockCounts : [String:Int]
    
    /// Just the block content itself as a web page.
    /// Suitable for embedding in a web view.
    public let blockURL : NSURL?
    
    /// If this is web content, can we actually display it.
    public let isResponsive : Bool
    
    /// A full web page for the block.
    /// Suitable for opening in a web browser.
    public let webURL : NSURL?
    
    /// Whether or not the block is graded.
    /// TODO: Match final API name
    public let graded : Bool?
    
    public init(type : CourseBlockType,
        children : [CourseBlockID],
        blockID : CourseBlockID,
        name : String,
        blockCounts : [String:Int] = [:],
        blockURL : NSURL? = nil,
        webURL : NSURL? = nil,
        format : String? = nil,
        isResponsive : Bool = true,
        graded : Bool = false) {
        self.type = type
        self.children = children
        self.name = name
        self.blockCounts = blockCounts
        self.blockID = blockID
        self.blockURL = blockURL
        self.webURL = webURL
        self.graded = graded
        self.format = format
        self.isResponsive = isResponsive
    }
}

