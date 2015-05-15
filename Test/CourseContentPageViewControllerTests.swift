//
//  CourseContentPageViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

private class MockCourseDataManager : CourseDataManager {
    let querier : CourseOutlineQuerier
    init(querier : CourseOutlineQuerier) {
        self.querier = querier
        super.init(interface : nil)
    }
    
    override func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        return querier
    }
}

class CourseContentPageViewControllerTests: SnapshotTestCase {
    
    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id)
    var router : OEXRouter!
    var environment : CourseContentPageViewController.Environment!
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline: outline, interface : nil)
        let dataManager = DataManager(courseDataManager: MockCourseDataManager(querier: querier))
        recordMode = true
        let routerEnvironment = OEXRouterEnvironment(analytics : nil, config : nil, dataManager : dataManager, interface : nil, session : nil, styles : OEXStyles())
        
        router = OEXRouter(environment: routerEnvironment)
        environment = CourseContentPageViewController.Environment(dataManager : dataManager, router : router)
        
        OEXStyles.setSharedStyles(OEXStyles())
    }
    
    override func tearDown() {
        super.tearDown()
        OEXStyles.setSharedStyles(nil)
    }
    
    func loadAndVerifyControllerWithInitialChild(initialChildID : CourseBlockID?, parentID : CourseBlockID, verifier : (CourseBlockID?, CourseContentPageViewController) -> Void) -> CourseContentPageViewController {
        
        let controller = CourseContentPageViewController(environment: environment!, courseID: outline.root, rootID: parentID, initialChildID: initialChildID)
        
        inScreenNavigationContext(controller) {
            let expectation = self.expectationWithDescription("course loaded")
            dispatch_async(dispatch_get_main_queue()) {
                let blockLoadedPromise = controller.t_blockIDForCurrentViewController()
                blockLoadedPromise.then {blockID -> Void in
                    verifier(blockID, controller)
                    expectation.fulfill()
                }
            }
            self.waitForExpectationsWithTimeout(1, handler: nil)
        }
        return controller
    }
    
    func testDefaultToFirstChild() {
        loadAndVerifyControllerWithInitialChild(nil, parentID: outline.root) { (blockID, _) in
            XCTAssertNotNil(blockID)
        }
    }

    func testShowsRequestedChild() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren()
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 1, "Need at least two children for this test")
        let childID = childIDs.last
        
        loadAndVerifyControllerWithInitialChild(childID, parentID: parent) { (blockID, _) in
            XCTAssertEqual(childID!, blockID!)
        }
    }
    
    func testInvalidRequestedChild() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren()
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 1, "Need at least three children for this test")
        let childID = childIDs.first
        
        let controller = loadAndVerifyControllerWithInitialChild("invalid child id", parentID: parent) { (blockID, _) in
            XCTAssertEqual(childID!, blockID!)
        }
    }
    
    func testNextButton() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren()
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.first
        
        let controller = loadAndVerifyControllerWithInitialChild(childID, parentID: parent) { (_, controller) in
            XCTAssertFalse(controller.t_prevButtonEnabled, "First child shouldn't have previous button enabled")
            XCTAssertTrue(controller.t_nextButtonEnabled, "First child should have next button enabled")
        }
        
        // Traverse through the entire child list going forward
        // verifying that we're viewing the right thing
        for childID in childIDs[1 ..< childIDs.count] {
            controller.t_goForward()
            
            let expectation = expectationWithDescription("controller went forward")
            controller.t_blockIDForCurrentViewController().then {blockID -> Void in
                expectation.fulfill()
                XCTAssertEqual(blockID!, childID)
            }
            waitForExpectationsWithTimeout(1, handler: nil)
            XCTAssertTrue(controller.t_prevButtonEnabled)
            XCTAssertEqual(controller.t_nextButtonEnabled, childID != childIDs.last!)
        }
    }
    
    func testPrevButton() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren()
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.last
        
        let controller = loadAndVerifyControllerWithInitialChild(childID, parentID: parent) { (_, controller) in
            XCTAssertTrue(controller.t_prevButtonEnabled, "Last child should have previous button enabled")
            XCTAssertFalse(controller.t_nextButtonEnabled, "Last child shouldn't have next button enabled")
        }
        
        // Traverse through the entire child list going backward
        // verifying that we're viewing the right thing
        for childID in childIDs.reverse()[1 ..< childIDs.count] {
            controller.t_goBackward()
            
            let expectation = expectationWithDescription("controller went backward")
            controller.t_blockIDForCurrentViewController().then {blockID -> Void in
                expectation.fulfill()
                XCTAssertEqual(blockID!, childID)
            }
            waitForExpectationsWithTimeout(1, handler: nil)
            XCTAssertTrue(controller.t_nextButtonEnabled)
            XCTAssertEqual(controller.t_prevButtonEnabled, childID != childIDs.first!)
        }
    }
    
    func testSnapshotContent() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren()
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 1, "Need at least two children for this test")
        let childID = childIDs.last
        loadAndVerifyControllerWithInitialChild(childID, parentID: parent) { (blockID, controller) in
            self.assertSnapshotValidWithContent(controller.navigationController!)
        }

    }
}
