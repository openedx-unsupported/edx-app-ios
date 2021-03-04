//
//  CourseOutline.swift
//  edX
//
//  Created by Akiva Leffert on 4/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public typealias CourseBlockID = String

public struct CourseOutline {
    
    enum Fields : String, RawStringExtractable {
        case Root = "root"
        case Blocks = "blocks"
        case BlockCounts = "block_counts"
        case BlockType = "type"
        case Descendants = "descendants"
        case DisplayName = "display_name"
        case DueDate = "due"
        case Format = "format"
        case Graded = "graded"
        case LMSWebURL = "lms_web_url"
        case StudentViewMultiDevice = "student_view_multi_device"
        case StudentViewURL = "student_view_url"
        case StudentViewData = "student_view_data"
        case Summary = "summary"
        case MinifiedBlockID = "block_id"
        case AuthorizationDenialReason = "authorization_denial_reason"
        case AuthorizationDenialMessage = "authorization_denial_message"
    }
    
    public let root : CourseBlockID
    public let blocks : [CourseBlockID:CourseBlock]
    private let parents : [CourseBlockID:CourseBlockID]
    
    public init(root : CourseBlockID, blocks : [CourseBlockID:CourseBlock]) {
        self.root = root
        self.blocks = blocks
        
        var parents : [CourseBlockID:CourseBlockID] = [:]
        for (blockID, block) in blocks {
            for child in block.children {
                parents[child] = blockID
            }
        }
        self.parents = parents
    }
    
    public init?(json : JSON) {
        if let root = json[Fields.Root].string, let blocks = json[Fields.Blocks].dictionaryObject {
            var validBlocks : [CourseBlockID:CourseBlock] = [:]
            for (blockID, blockBody) in blocks {
                let body = JSON(blockBody)
                let webURL = NSURL(string: body[Fields.LMSWebURL].stringValue)
                let children = body[Fields.Descendants].arrayObject as? [String] ?? []
                let name = body[Fields.DisplayName].string
                let dueDate = body[Fields.DueDate].string
                let blockURL = body[Fields.StudentViewURL].string.flatMap { NSURL(string:$0) }
                let format = body[Fields.Format].string
                let typeName = body[Fields.BlockType].string ?? ""
                let multiDevice = body[Fields.StudentViewMultiDevice].bool ?? false
                let blockCounts : [String:Int] = (body[Fields.BlockCounts].object as? NSDictionary)?.mapValues {
                    $0 as? Int ?? 0
                } ?? [:]
                let graded = body[Fields.Graded].bool ?? false
                let minifiedBlockID = body[Fields.MinifiedBlockID].string
                let authorizationDenialReason = body[Fields.AuthorizationDenialReason].string
                let authorizationDenialMessage = body[Fields.AuthorizationDenialMessage].string
                
                var type : CourseBlockType
                if let category = CourseBlock.Category(rawValue: typeName) {
                    switch category {
                    case .Course:
                        type = .Course
                    case .Chapter:
                        type = .Chapter
                    case .Section:
                        type = .Section
                    case .Unit:
                        type = .Unit
                    case .HTML:
                        type = .HTML
                    case .Problem:
                        type = .Problem
                    case .OpenAssesment:
                        type = .OpenAssesment
                    case .Video :
                        let bodyData = (body[Fields.StudentViewData].object as? NSDictionary).map { [Fields.Summary.rawValue : $0 ] }
                        let summary = OEXVideoSummary(dictionary: bodyData ?? [:], videoID: blockID, unitURL: blockURL?.absoluteString, name : name ?? Strings.untitled)
                        type = .Video(summary)
                    case .Discussion:
                        // Inline discussion is in progress feature. Will remove this code when it's ready to ship
                        type = .Unknown(typeName)
                        
                        if OEXConfig.shared().discussionsEnabled {
                            let bodyData = body[Fields.StudentViewData].object as? NSDictionary
                            let discussionModel = DiscussionModel(dictionary: bodyData ?? [:])
                            type = .Discussion(discussionModel)
                        }
                    }
                }
                else {
                    type = .Unknown(typeName)
                }
                
                validBlocks[blockID] = CourseBlock(
                    type: type,
                    children: children,
                    blockID: blockID,
                    minifiedBlockID: minifiedBlockID,
                    name: name,
                    dueDate: dueDate,
                    blockCounts : blockCounts,
                    blockURL : blockURL,
                    webURL: webURL,
                    format : format,
                    multiDevice : multiDevice,
                    graded : graded,
                    authorizationDenialReason: authorizationDenialReason,
                    authorizationDenialMessage: authorizationDenialMessage
                )
            }
            self = CourseOutline(root: root, blocks: validBlocks)
        }
        else {
            return nil
        }
    }
    
    func parentOfBlockWithID(blockID : CourseBlockID) -> CourseBlockID? {
        return self.parents[blockID]
    }
}

public enum CourseBlockType: Equatable {
    case Unknown(String)
    case Course
    case Chapter // child of course
    case Section // child of chapter
    case Unit // child of section
    case Video(OEXVideoSummary)
    case Problem
    case OpenAssesment
    case HTML
    case Discussion(DiscussionModel)
    
    public var asVideo : OEXVideoSummary? {
        switch self {
        case let .Video(summary):
            return summary
        default:
            return nil
        }
    }

    var name: String {
        get { return String(describing: self) }
    }
}

public class CourseBlock {
    
    /// Simple list of known block categories strings
    public enum Category : String {
        case Chapter = "chapter"
        case Course = "course"
        case HTML = "html"
        case Problem = "problem"
        case OpenAssesment = "openassessment"
        case Section = "sequential"
        case Unit = "vertical"
        case Video = "video"
        case Discussion = "discussion"
    }
    
    public enum AuthorizationDenialReason : String {
        case featureBasedEnrollment = "Feature-based Enrollments"
        case none = "none"
    }
    
    public let type : CourseBlockType
    public let blockID : CourseBlockID
    /// This is the alpha numeric identifier at the end of the blockID above.
    public let minifiedBlockID: String?
    
    /// Children in the navigation hierarchy.
    /// Note that this may be different than the block's list of children, server side
    /// Since we flatten out the hierarchy for display
    public let children : [CourseBlockID]
    
    /// Title of block. Keep this private so people don't use it as the displayName by accident
    private let name : String?
    
    public let dueDate : String?
    
    /// Actual title of the block. Not meant to be user facing - see displayName
    public var internalName : String? {
        return name
    }
    
    /// User visible name of the block.
    public var displayName : String {
        guard let name = name, !name.isEmpty else {
            return Strings.untitled
        }
        return name
    }
    
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
    public let multiDevice : Bool
    
    /// A full web page for the block.
    /// Suitable for opening in a web browser.
    public let webURL : NSURL?
    
    /// Whether or not the block is graded.
    /// TODO: Match final API name
    public let graded : Bool?
    
    /// Authorization Denial Reason if the block content is gated
    public let authorizationDenialReason: AuthorizationDenialReason
    
    /// Authorization Denial Message if the block content is gated
    public let authorizationDenialMessage: String?
    
    /// Property to represent gated content
    public var isGated: Bool {
        return authorizationDenialReason == .featureBasedEnrollment
    }
    
    public init(type : CourseBlockType,
        children : [CourseBlockID],
        blockID : CourseBlockID,
        minifiedBlockID: String?,
        name : String?,
        dueDate : String? = nil,
        blockCounts : [String:Int] = [:],
        blockURL : NSURL? = nil,
        webURL : NSURL? = nil,
        format : String? = nil,
        multiDevice : Bool,
        graded : Bool = false,
        authorizationDenialReason: String? = nil,
        authorizationDenialMessage: String? = nil) {
        self.type = type
        self.children = children
        self.name = name
        self.dueDate = dueDate
        self.blockCounts = blockCounts
        self.blockID = blockID
        self.minifiedBlockID = minifiedBlockID
        self.blockURL = blockURL
        self.webURL = webURL
        self.graded = graded
        self.format = format
        self.multiDevice = multiDevice
        self.authorizationDenialReason = AuthorizationDenialReason(rawValue: authorizationDenialReason ?? AuthorizationDenialReason.none.rawValue) ?? AuthorizationDenialReason.none
        self.authorizationDenialMessage = authorizationDenialMessage
    }
}

