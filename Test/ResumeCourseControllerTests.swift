//
//  ResumeCourseControllerTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 06/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX


class MockResumeCourseDelegate : ResumeCourseControllerDelegate {
    var didFetchAction : ((ResumeCourseItem?) -> Void)?
    func resumeCourseControllerDidFetchResumeCourseItem(item: ResumeCourseItem?) {
        didFetchAction?(item)
    }
}


class ResumeCourseControllerTests: SnapshotTestCase {

    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var environment: TestRouterEnvironment!
    
    var resumeCourseItem = CourseOutlineTestDataFactory.resumeCourseItem
    let resumeCourseProvider = MockResumeCourseProvider()
    
    var rootController : ResumeCourseController?
    var sectionController : ResumeCourseController?
    var nonVideoSectionController : ResumeCourseController?
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        environment = TestRouterEnvironment()
        environment.mockCourseDataManager.querier = querier
        
        environment.mockNetworkManager.interceptWhenMatching({_ in return true}, successResponse: { () -> (Data?,ResumeCourseItem) in
            return (nil, self.resumeCourseItem)
        })
        
        rootController = ResumeCourseController(blockID: nil,
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            resumeCourseProvider : resumeCourseProvider, forMode: .full)
        
        sectionController = ResumeCourseController(blockID: "unit3",
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            resumeCourseProvider: resumeCourseProvider, forMode: .full)
        
        nonVideoSectionController = ResumeCourseController(blockID: "unit1",
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
        resumeCourseItem = ResumeCourseItem(lastVisitedBlockID: "block2", lastVisitedBlockName: "Block 2")
        
        sectionController!.t_saveResumeCourse(item: resumeCourseItem)
        let item = sectionController!.t_getResumeCourseFor(courseID: outline.root)!
        
        let found = item.lastVisitedBlockID == "block2" && item.lastVisitedBlockName == "Block 2"
        
        XCTAssertTrue(found, "Set Last Accessed Success")
    }
    
    func testVideoMode() {
        let videoSectionController = ResumeCourseController(blockID: nil, dataManager: environment.dataManager, networkManager: environment.networkManager, courseQuerier: CourseOutlineQuerier(courseID: outline.root, outline : outline), resumeCourseProvider: resumeCourseProvider, forMode: .video)
        
        XCTAssertFalse(videoSectionController.t_canShowResumeCourse())
        XCTAssertFalse(videoSectionController.t_canUpdateResumeCourse())
    }
}
