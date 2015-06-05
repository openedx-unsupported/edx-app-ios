//
//  CourseOutlineTestDataFactory.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class CourseOutlineTestDataFactory {

    // This is temporarily part of the edX target instead of the edXTests target so we can use it as a fixture
    // during development. When that is not being done any more we should hook it up to the test target only
    
    public static func freshCourseOutline(courseID : String) -> CourseOutline {
        return CourseOutline(
            root : courseID,
            blocks : [
                courseID: CourseBlock(type: CourseBlockType.Course, children : ["chapter1", "chapter2", "chapter3", "chapter4"], blockID : "course", name : "A Course", blockCounts : ["video" : 1]),
                "chapter1": CourseBlock(type: CourseBlockType.Chapter, children : ["section1.1", "section1.2"], blockID : "chapter1", name : "Chapter 1", blockCounts : ["video" : 1]),
                "chapter2": CourseBlock(type: CourseBlockType.Chapter, children : ["section2.1", "section2.2"], blockID : "chapter2", name : "Chapter 2"),
                "chapter3": CourseBlock(type: CourseBlockType.Chapter, children : [], blockID : "chapter3", name : "Chapter 3"),
                "chapter4": CourseBlock(type: CourseBlockType.Chapter, children : [], blockID : "chapter4", name : "Chapter 4"),
                "section1.1": CourseBlock(type: CourseBlockType.Section, children : ["unit1", "unit2"], blockID : "section1.1", name : "Section 1", blockCounts : ["video" : 1]),
                "section1.2": CourseBlock(type: CourseBlockType.Section, children : ["unit3"], blockID : "section1.2", name : "Section 2"),
                "section2.1": CourseBlock(type: CourseBlockType.Section, children : [], blockID : "section2.1", name : "Section 1"),
                "section2.2": CourseBlock(type: CourseBlockType.Section, children : [], blockID : "section2.2", name : "Section 2"),
                "unit1": CourseBlock(type: CourseBlockType.Unit, children : ["block1"], blockID : "unit1", name : "Unit 1"),
                "unit2": CourseBlock(type: CourseBlockType.Unit, children : ["block2", "block3", "block4", "block5"], blockID : "unit2", name : "Unit 2", blockCounts : ["video" : 1]),
                "unit3": CourseBlock(type: CourseBlockType.Unit, children : [], blockID : "unit3", name : "Unit 3"),
                "block1": CourseBlock(type: CourseBlockType.HTML, children : [], blockID : "block1", name : "Block 1"),
                "block2": CourseBlock(type: CourseBlockType.HTML, children : [], blockID : "block2", name : "Block 2"),
                "block3": CourseBlock(type: CourseBlockType.Problem, children : [], blockID : "block3", name : "Block 3"),
                "block4": CourseBlock(type: CourseBlockType.Video(OEXVideoSummaryTestDataFactory.localVideoWithID("block4", pathIDs: ["chapter1", "section1.1", "unit2"])), children : [], blockID : "block4", name : "Block 4"),
                "block5": CourseBlock(type: CourseBlockType.Unknown("something"), children : [], blockID : "block5", name : "Block 5")
            ])
    }
    
    public static func knownParentIDWithMultipleChildren() -> CourseBlockID {
        return "unit2"
    }
    
    public static func knownSection() -> CourseBlockID {
        return "section1.1"
    }
    
    public static func knownEmptySection() -> CourseBlockID {
        return "section2.1"
    }

}