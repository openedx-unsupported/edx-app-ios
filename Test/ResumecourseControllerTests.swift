//
//  ResumecourseControllerTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 06/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX


class MockResumeCourseDelegate : ResumeCourseControllerDelegate {
    var didFetchAction : ((ResumeCourse?) -> Void)?
    func resumeCourseControllerDidFetchResumeCourseItem(item: ResumeCourse?) {
        didFetchAction?(item)
    }
}


class ResumecourseControllerTests: SnapshotTestCase {

    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var environment: TestRouterEnvironment!
    
    var resumeCourseItem = CourseOutlineTestDataFactory.knownResumeCourseItem
    let resumeCourseProvider = MockResumeCourseProvider()
    
    var rootController : ResumeCoursseController?
    var sectionController : ResumeCoursseController?
    var nonVideoSectionController : ResumeCoursseController?
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        environment = TestRouterEnvironment()
        environment.mockCourseDataManager.querier = querier
        
        environment.mockNetworkManager.interceptWhenMatching({_ in return true}, successResponse: { () -> (Data?,ResumeCourse) in
            return (nil, self.resumeCourseItem)
        })
        
        rootController = ResumeCoursseController(blockID: nil,
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            resumeCourseProvider : resumeCourseProvider, forMode: .full)
        
        sectionController = ResumeCoursseController(blockID: "unit3",
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            resumeCourseProvider: resumeCourseProvider, forMode: .full)
        
        nonVideoSectionController = ResumeCoursseController(blockID: "unit1",
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            resumeCourseProvider: resumeCourseProvider, forMode: .full)
    }
    
    override func tearDown() {
        super.tearDown()
        environment = nil
        resumeCourseProvider.resetResumeCourseItem()
    }
    
    func testSetResumeCourseItem() {
        resumeCourseItem = ResumeCourse(lastVisitedBlockID: "block2", lastVisitedBlockName: "Block 2")
        
        sectionController!.t_saveResumeCourse(item: resumeCourseItem)
        let item = sectionController!.t_getResumeCourseFor(courseID: outline.root)!
        
        let found = item.lastVisitedBlockID == "block2" && item.lastVisitedBlockName == "Block 2"
        
        XCTAssertTrue(found, "Set Last Accessed Success")
    }
    
    func testVideoMode() {
        let videoSectionController = ResumeCoursseController(blockID: nil, dataManager: environment.dataManager, networkManager: environment.networkManager, courseQuerier: CourseOutlineQuerier(courseID: outline.root, outline : outline), resumeCourseProvider: resumeCourseProvider, forMode: .video)
        
        XCTAssertFalse(videoSectionController.t_canShowResumeCourse())
        XCTAssertFalse(videoSectionController.t_canUpdateResumeCourse())
    }
}
