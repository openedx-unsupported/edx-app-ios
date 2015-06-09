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
    
    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id)
    var router : OEXRouter!
    var environment : CourseOutlineViewController.Environment!
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        let dataManager = DataManager(courseDataManager: MockCourseDataManager(querier: querier))
        
        let routerEnvironment = OEXRouterEnvironment(analytics : nil, config : nil, dataManager : dataManager, interface : nil, session : nil, styles : OEXStyles())
        
        router = OEXRouter(environment: routerEnvironment)
        environment = CourseOutlineViewController.Environment(dataManager : dataManager, router : router, styles : routerEnvironment.styles)
        
        OEXStyles.setSharedStyles(OEXStyles())
    }
    
    func loadAndVerifyControllerWithBlockID(blockID : CourseBlockID, verifier : CourseOutlineViewController -> Void) -> CourseOutlineViewController {
        
        let controller = CourseOutlineViewController(environment: environment!, courseID: outline.root, rootID: blockID)
        
        inScreenNavigationContext(controller) {
            let expectation = self.expectationWithDescription("course loaded")
            dispatch_async(dispatch_get_main_queue()) {
                let blockLoadedPromise = controller.t_setup()
                blockLoadedPromise.then {_ -> Void in
                    verifier(controller)
                    expectation.fulfill()
                }
            }
            self.waitForExpectationsWithTimeout(1, handler: nil)
        }
        return controller
    }
    
    func testSnapshotContentCourse() {
        loadAndVerifyControllerWithBlockID(outline.root) { controller in
            self.assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testSnapshotContentChapter() {
        loadAndVerifyControllerWithBlockID(CourseOutlineTestDataFactory.knownSection()) { controller in
            self.assertSnapshotValidWithContent(controller.navigationController!)
        }
    }


}
