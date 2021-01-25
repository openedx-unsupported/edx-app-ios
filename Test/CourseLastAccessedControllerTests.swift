//
//  CourseLastAccessedControllerTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 06/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX


class MockLastAccessedDelegate : CourseLastAccessedControllerDelegate {
    var didFetchAction : ((CourseLastAccessed?) -> Void)?
    func courseLastAccessedControllerDidFetchLastAccessedItem(item: CourseLastAccessed?) {
        didFetchAction?(item)
    }
}


class CourseLastAccessedControllerTests: SnapshotTestCase {

    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var environment: TestRouterEnvironment!
    
    var lastAccessedItem = CourseOutlineTestDataFactory.knownLastAccessedItem
    let lastAccessedProvider = MockLastAccessedProvider()
    
    var rootController : CourseLastAccessedController?
    var sectionController : CourseLastAccessedController?
    var nonVideoSectionController : CourseLastAccessedController?
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        environment = TestRouterEnvironment()
        environment.mockCourseDataManager.querier = querier
        
        environment.mockNetworkManager.interceptWhenMatching({_ in return true}, successResponse: { () -> (Data?,CourseLastAccessed) in
            return (nil, self.lastAccessedItem)
        })
        
        rootController = CourseLastAccessedController(blockID: nil,
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            lastAccessedProvider : lastAccessedProvider, forMode: .full)
        
        sectionController = CourseLastAccessedController(blockID: "unit3",
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            lastAccessedProvider: lastAccessedProvider, forMode: .full)
        
        nonVideoSectionController = CourseLastAccessedController(blockID: "unit1",
            dataManager: environment.dataManager,
            networkManager: environment.networkManager,
            courseQuerier: querier,
            lastAccessedProvider: lastAccessedProvider, forMode: .full)
    }
    
    override func tearDown() {
        super.tearDown()
        environment = nil
        lastAccessedProvider.resetLastAccessedItem()
    }
    
    func testSetLastAccessedItem() {
        lastAccessedItem = CourseLastAccessed(lastVisitedBlockID: "block2", lastVisitedBlockName: "Block 2")
        
        sectionController!.t_saveLastAccess(item: lastAccessedItem)
        let item = sectionController!.t_getLastAccessFor(courseID: outline.root)!
        
        let found = item.lastVisitedBlockID == "block2" && item.lastVisitedBlockName == "Block 2"
        
        XCTAssertTrue(found, "Set Last Accessed Success")
    }
    
    func testVideoMode() {
        let videoSectionController = CourseLastAccessedController(blockID: nil, dataManager: environment.dataManager, networkManager: environment.networkManager, courseQuerier: CourseOutlineQuerier(courseID: outline.root, outline : outline), lastAccessedProvider: lastAccessedProvider, forMode: .video)
        
        XCTAssertFalse(videoSectionController.t_canShowLastAccessed())
        XCTAssertFalse(videoSectionController.t_canUpdateLastAccessed())
    }
}
