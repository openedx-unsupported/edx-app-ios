//
//  CourseOutlineTestDataFactory.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
@testable import edX

open class CourseOutlineTestDataFactory {

    // This is temporarily part of the edX target instead of the edXTests target so we can use it as a fixture
    // during development. When that is not being done any more we should hook it up to the test target only
    
    public static func freshCourseOutline(_ courseID : String) -> CourseOutline {
        return CourseOutline(
            root : courseID,
            blocks : [
                courseID: CourseBlock(type: CourseBlockType.Course, children : ["chapter1", "chapter2", "chapter3", "chapter4"], blockID : courseID, minifiedBlockID: "123456", name : "A Course", blockCounts : ["video" : 1], multiDevice : true),
                "chapter1": CourseBlock(type: CourseBlockType.Chapter, children : ["section1.1", "section1.2", "section1.3", "section1.4"], blockID : "chapter1", minifiedBlockID: "123456", name : "Chapter 1", blockCounts : ["video" : 1], multiDevice : true),
                "chapter2": CourseBlock(type: CourseBlockType.Chapter, children : ["section2.1", "section2.2"], blockID : "chapter2", minifiedBlockID: "123456", name : "Chapter 2", multiDevice : true),
                "chapter3": CourseBlock(type: CourseBlockType.Chapter, children : ["section3.1"], blockID : "chapter3", minifiedBlockID: "123456", name : "Chapter 3", multiDevice : true),
                "chapter4": CourseBlock(type: CourseBlockType.Chapter, children : ["section4.1"], blockID : "chapter4", minifiedBlockID: "123456", name : "Chapter 2", blockCounts : ["video" : 1], multiDevice : true),
                "section1.1": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit2"], blockID : "section1.1", minifiedBlockID: "123456", name : "Section 1", blockCounts : ["video" : 1], multiDevice : true),
                "section1.2": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit2"], blockID : "section1.2", minifiedBlockID: "123456", name : "Section 2", blockCounts : ["video" : 2], multiDevice : true),
                "section1.3": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit2","unit3"], blockID : "section1.3", minifiedBlockID: "123456", name : "Section 3", blockCounts : ["video" : 3], multiDevice : true),
                "section1.4": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit2", "unit4"], blockID : "section1.4", minifiedBlockID: "123456", name : "Section 4", blockCounts : ["video" : 2], multiDevice : true),
                "section2.1": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit2","unit3"], blockID : "section2.1", minifiedBlockID: "123456", name : "Section 1", blockCounts : ["video" : 3], multiDevice : true),
                "section2.2": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit2"], blockID : "section2.2", minifiedBlockID: "123456", name : "Section 2", blockCounts : ["video" : 2], multiDevice : true),
                "section3.1": CourseBlock(type: CourseBlockType.Section, children : [], blockID : "section3.1", minifiedBlockID: "123456", name : "Section 1", dueDate:"2017-08-04T00:00:00Z", format:"Homework", multiDevice : true, graded : true),
                "section4.1": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit3"], blockID : "section4.1", minifiedBlockID: "123456", name : "Section 1", blockCounts : ["video" : 1], multiDevice : true),
                "unit1": CourseBlock(type: CourseBlockType.Unit, children : ["block1"], blockID : "unit1", minifiedBlockID: "123456", name : "Unit 1", multiDevice : true),
                "unit2": CourseBlock(type: CourseBlockType.Unit, children : ["block2", "block3", "block4", "block5"], blockID : "unit2", minifiedBlockID: "123456", name : "Unit 2", blockCounts : ["video" : 1], multiDevice : true),
                "unit3": CourseBlock(type: CourseBlockType.Unit, children : ["block4","block4"], blockID : "unit3", minifiedBlockID: "block_id", name : "Unit 3", blockCounts : ["video" : 2], multiDevice : true),
                "unit4": CourseBlock(type: CourseBlockType.Unit, children : ["block4","block4","block4"], blockID : "unit4", minifiedBlockID: "block_id", name : "Unit 4", blockCounts : ["video" : 3], multiDevice : true),
                "block1": CourseBlock(type: CourseBlockType.HTML, children : [], blockID : "block1", minifiedBlockID: "123456", name : "Block 1", multiDevice : true),
                "block2": CourseBlock(type: CourseBlockType.HTML, children : [], blockID : "block2", minifiedBlockID: "123456", name : "Block 2", multiDevice : true),
                "block3": CourseBlock(type: CourseBlockType.Problem, children : [], blockID : "block3", minifiedBlockID: "123456", name : "Block 3", multiDevice : true, authorizationDenialReason: "Feature-based Enrollments", authorizationDenialMessage: "Gradded Assessments"),
                "block4": CourseBlock(type: CourseBlockType.Video(OEXVideoSummaryTestDataFactory.localVideoWithID("block4", pathIDs: ["chapter1", "section1.1", "unit2"], encodings:["mobile_low":["file_size":3700000, "url":"https://www.example.com/video.mp4"]] )), children : [], blockID : "block4", minifiedBlockID: "123456", name : "Block 4", blockCounts : ["video" : 1], multiDevice : true),
                "block5": CourseBlock(type: CourseBlockType.Unknown("something"), children : [], blockID : "block5", minifiedBlockID: "123456", name : "Block 5", multiDevice : false)
            ])
    }
    

    static let knownLastAccessedItem = CourseLastAccessed(moduleId: "unit2", moduleName: "unit2")
    static let knownParentIDWithMultipleChildren = "unit2"
    static let knownSection = "section1.1"
    static let knownEmptySection = "section2.1"
    static let knownVideoFilterableSection = "unit2"
    static let knownHTMLBlockIDs = ["block1", "block2"]
    static let knownLocalVideoID = "block4"
}
