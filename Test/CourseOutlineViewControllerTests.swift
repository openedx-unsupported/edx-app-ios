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
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        courseDataManager = MockCourseDataManager(querier: querier)
        let dataManager = DataManager(courseDataManager: courseDataManager)
        
        let routerEnvironment = OEXRouterEnvironment(analytics : nil, config : nil, dataManager : dataManager, interface : nil, session : nil, styles : OEXStyles())
        
        router = OEXRouter(environment: routerEnvironment)
        environment = CourseOutlineViewController.Environment(dataManager : dataManager, router : router, styles : routerEnvironment.styles)
    }
    
    func loadAndVerifyControllerWithBlockID(blockID : CourseBlockID, verifier : CourseOutlineViewController -> (Void -> Void)?) -> CourseOutlineViewController {
        
        let controller = CourseOutlineViewController(environment: environment!, courseID: outline.root, rootID: blockID)
        
        inScreenNavigationContext(controller) {
            let expectation = self.expectationWithDescription("course loaded")
            var next : (Void -> Void)? = nil
            dispatch_async(dispatch_get_main_queue()) {
                let blockLoadedPromise = controller.t_setup()
                blockLoadedPromise.then {_ -> Void in
                    next = verifier(controller)
                    expectation.fulfill()
                }
            }
            self.waitForExpectations()
            next?()
        }
        return controller
    }
    
    func testVideoModeSwitches() {
        // First ensure that there are non video sections that will be filtered
        let querier = courseDataManager.querierForCourseWithID("anything")
        let fullChildren = querier.childrenOfBlockWithID(outline.root, forMode: .Full)
        let filteredChildren = querier.childrenOfBlockWithID(outline.root, forMode: .Video)
        
        let expectation = expectationWithDescription("Loaded children")
        when(fullChildren, filteredChildren).then {(fullChildren, filteredChildren) -> Void in
            XCTAssertGreaterThan(fullChildren.count, filteredChildren.count)
            expectation.fulfill()
        }
        
        self.waitForExpectations()
        
        // Now make sure we're in full mode
        courseDataManager.currentOutlineMode = .Full

        loadAndVerifyControllerWithBlockID(outline.root) {controller in
            let originalBlockCount = controller.t_currentChildCount()
            return {
                // Switch to video mode
                self.courseDataManager.currentOutlineMode = .Video
                let expectation = self.expectationWithDescription("Reloaded children")
                let blockLoadedPromise = controller.t_setup()
                blockLoadedPromise.then {_ -> Void in
                    // And check that fewer things are visible
                    XCTAssertGreaterThan(originalBlockCount, controller.t_currentChildCount())
                    expectation.fulfill()
                }
                self.waitForExpectations()
                
            }
            
        }
    }
    
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
