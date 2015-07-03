//
//  CourseOutlineViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX

class CourseOutlineViewControllerTests: SnapshotTestCase {
    
    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var router : OEXRouter!
    var environment : CourseOutlineViewController.Environment!
    var courseDataManager : MockCourseDataManager!
    let lastAccessedItem = CourseOutlineTestDataFactory.knownLastAccessedItem()
    let networkManager = MockNetworkManager(baseURL: NSURL(string: "www.example.com")!)
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        courseDataManager = MockCourseDataManager(querier: querier)
        let dataManager = DataManager(courseDataManager: courseDataManager)
        
        let routerEnvironment = OEXRouterEnvironment(analytics : nil, config : nil, dataManager : dataManager, interface : nil, session : nil, styles : OEXStyles(), networkManager : networkManager)
        
        router = OEXRouter(environment: routerEnvironment)
        environment = CourseOutlineViewController.Environment(dataManager : dataManager, reachability : MockReachability(), router : router, styles : routerEnvironment.styles, networkManager: networkManager)
    }
    
    func loadAndVerifyControllerWithBlockID(blockID : CourseBlockID, verifier : CourseOutlineViewController -> (XCTestExpectation -> Void)?) {
        
        let blockIdOrNilIfRoot : CourseBlockID? = blockID == outline.root ? nil : blockID
        let controller = CourseOutlineViewController(environment: environment!, courseID: outline.root, rootID: blockIdOrNilIfRoot)
        
        let expectation = self.expectationWithDescription("course loaded")
        let updateStream = BackedStream<Void>()
        
        inScreenNavigationContext(controller) {
            dispatch_async(dispatch_get_main_queue()) {
                let blockLoadedStream = controller.t_setup()
                updateStream.backWithStream(blockLoadedStream)
                updateStream.listen(controller) {[weak controller] _ in
                    updateStream.removeBacking()
                    if let next = controller.flatMap({ verifier($0) }) {
                        next(expectation)
                    }
                    else {
                        expectation.fulfill()
                    }
                }
            }
        }
        self.waitForExpectations()
    }
    
    func testVideoModeSwitches() {
        // First ensure that there are non video sections that will be filtered
        let querier = courseDataManager.querierForCourseWithID("anything")
        let fullChildren = querier.childrenOfBlockWithID(outline.root, forMode: .Full)
        let filteredChildren = querier.childrenOfBlockWithID(outline.root, forMode: .Video)
        
        let expectation = expectationWithDescription("Loaded children")
        let stream = joinStreams(fullChildren, filteredChildren).listen(NSObject()) {
            let full = $0.value!.0
            let filtered = $0.value!.1
            XCTAssertGreaterThan(full.children.count, filtered.children.count)
            expectation.fulfill()
        }
        self.waitForExpectations()
        
        
        // Now make sure we're in full mode
        courseDataManager.currentOutlineMode = .Full

        loadAndVerifyControllerWithBlockID(outline.root) {controller in
            let originalBlockCount = controller.t_currentChildCount()
            return {expectation in
                // Switch to video mode
                self.courseDataManager.currentOutlineMode = .Video
                let blockLoadedStream = controller.t_setup()
                blockLoadedStream.listen(controller) {_ in
                    // And check that fewer things are visible
                    XCTAssertGreaterThan(originalBlockCount, controller.t_currentChildCount())
                    expectation.fulfill()
                }
            }
            
        }
    }
    
//    func testLastAccessedItem() {
//        loadAndVerifyControllerWithBlockID(outline.root) {controller in
//            let doesShow = controller.t_populateLastAccessedItem(self.lastAccessedItem)
//            XCTAssertTrue(doesShow, "View doesn't show despite given Item")
//            return nil
//        }
//    }
//    
//    func testSetLastAccessedItemTriggerForRootNode() {
//        loadAndVerifyControllerWithBlockID(outline.root) { controller in
//            XCTAssertFalse(controller.t_didTriggerSetLastAccessed(), "Triggered Set last accessed while the controller was on root node")
//            return nil
//        }
//        
//    }
    
//    func testSetLastAccessedItemTrigger() {
//        loadAndVerifyControllerWithBlockID("chapter4") { controller in
//            XCTAssertTrue(controller.t_didTriggerSetLastAccessed(), "Did not trigger setLastAccessed")
//            return nil
//        }
//        
//    }
    
    func testSnapshotEmptySection() {
        courseDataManager.currentOutlineMode = .Video
        loadAndVerifyControllerWithBlockID(CourseOutlineTestDataFactory.knownEmptySection()) {
            self.assertSnapshotValidWithContent($0.navigationController!)
            return nil
        }
    }

    func testSnapshotContentCourse() {
        loadAndVerifyControllerWithBlockID(outline.root) {
            self.assertSnapshotValidWithContent($0.navigationController!)
            return nil
        }
    }
    
    
    func testSnapshotContentChapter() {
        loadAndVerifyControllerWithBlockID(CourseOutlineTestDataFactory.knownSection()) {
            self.assertSnapshotValidWithContent($0.navigationController!)
            return nil
        }
    }

}
