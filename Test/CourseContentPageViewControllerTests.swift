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

class CourseContentPageViewControllerTests: SnapshotTestCase {
    
    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var router : OEXRouter!
    var environment : CourseContentPageViewController.Environment!
    var tracker : OEXMockAnalyticsTracker!
    let networkManager = MockNetworkManager(baseURL: NSURL(string: "www.example.com")!)
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline: outline)
        let dataManager = DataManager(courseDataManager: MockCourseDataManager(querier: querier))
        
        let analytics = OEXAnalytics()
        tracker = OEXMockAnalyticsTracker()
        analytics.addTracker(tracker)
        
        let routerEnvironment = OEXRouterEnvironment(analytics : analytics, config : nil, dataManager : dataManager, interface : nil, session : nil, styles : OEXStyles(), networkManager : networkManager)
        
        router = OEXRouter(environment: routerEnvironment)
        environment = CourseContentPageViewController.Environment(
            analytics: analytics,
            dataManager : dataManager,
            router : router,
            styles : routerEnvironment.styles)
    }
    
    func loadAndVerifyControllerWithInitialChild(initialChildID : CourseBlockID?, parentID : CourseBlockID, verifier : ((CourseBlockID?, CourseContentPageViewController) -> Void)? = nil) -> CourseContentPageViewController {
        
        let controller = CourseContentPageViewController(environment: environment!, courseID: outline.root, rootID: parentID, initialChildID: initialChildID)
        
        inScreenNavigationContext(controller) {
            let expectation = self.expectationWithDescription("course loaded")
            dispatch_async(dispatch_get_main_queue()) {
                let blockLoadedStream = controller.t_blockIDForCurrentViewController()
                blockLoadedStream.listen(controller) {blockID in
                    verifier?(blockID.value, controller)
                    expectation.fulfill()
                }
            }
            self.waitForExpectations()
        }
        return controller
    }
    
    func testDefaultToFirstChild() {
        let childIDs = outline.blocks[outline.root]!.children
        XCTAssertTrue(childIDs.count > 1, "Need at least two children for this test")
        let childID = childIDs.first
        
        loadAndVerifyControllerWithInitialChild(nil, parentID: outline.root) { (blockID, _) in
            XCTAssertEqual(childID!, blockID!)
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
        XCTAssertTrue(childIDs.count > 1, "Need at least two children for this test")
        let childID = childIDs.first
        
        loadAndVerifyControllerWithInitialChild("invalid child id", parentID: parent) { (blockID, _) in
            XCTAssertEqual(childID!, blockID!)
        }
    }
    
    func testNextButton() {
        let childIDs = outline.blocks[outline.root]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.first
        
        let controller = loadAndVerifyControllerWithInitialChild(childID, parentID: outline.root) { (_, controller) in
            XCTAssertFalse(controller.t_prevButtonEnabled, "First child shouldn't have previous button enabled")
            XCTAssertTrue(controller.t_nextButtonEnabled, "First child should have next button enabled")
        }
        
        // Traverse through the entire child list going forward
        // verifying that we're viewing the right thing
        for childID in childIDs[1 ..< childIDs.count] {
            controller.t_goForward()
            
            let expectation = expectationWithDescription("controller went forward")
            controller.t_blockIDForCurrentViewController().listen(controller) {
                expectation.fulfill()
                XCTAssertEqual($0.value!, childID)
            }
            self.waitForExpectations()
            XCTAssertTrue(controller.t_prevButtonEnabled)
            XCTAssertEqual(controller.t_nextButtonEnabled, childID != childIDs.last!)
        }
    }
    
    func testPrevButton() {
        let childIDs = outline.blocks[outline.root]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.last
        
        let controller = loadAndVerifyControllerWithInitialChild(childID, parentID: outline.root) { (_, controller) in
            XCTAssertTrue(controller.t_prevButtonEnabled, "Last child should have previous button enabled")
            XCTAssertFalse(controller.t_nextButtonEnabled, "Last child shouldn't have next button enabled")
        }
        
        // Traverse through the entire child list going backward
        // verifying that we're viewing the right thing
        for _ in Array(childIDs.reverse())[1 ..< childIDs.count] {
            controller.t_goBackward()
            
            let expectation = expectationWithDescription("controller went backward")
            controller.t_blockIDForCurrentViewController().listen(controller) {blockID in
                expectation.fulfill()
            }
            self.waitForExpectations()
        }
    }
    
    func testScreenAnalyticsEmitted() {
        let childIDs = outline.blocks[outline.root]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.first
        
        loadAndVerifyControllerWithInitialChild(childID, parentID: outline.root) {_ in
            let events = (self.tracker.observedEvents.flatMap { return $0 as? OEXMockAnalyticsScreenRecord })
            XCTAssertEqual(events.count, 2) // 1 for the page screen and one for its child
            let event = events[0]
            XCTAssertNotNil(event)
            XCTAssertEqual(event.screenName, OEXAnalyticsScreenUnitDetail)
            XCTAssertEqual(event.courseID, self.outline.root)
            XCTAssertEqual(event.value, self.outline.blocks[self.outline.root]?.name)
        }
        
    }
    
    func testPageAnalyticsEmitted() {
        let childIDs = outline.blocks[outline.root]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.first
        
        let controller = loadAndVerifyControllerWithInitialChild(childID, parentID: outline.root)
        
        // Traverse through the entire child list going backward
        // verifying that we're viewing the right thing
        for _ in childIDs[1 ..< childIDs.count] {
            controller.t_goForward()
            
            let expectation = expectationWithDescription("controller went backward")
            controller.t_blockIDForCurrentViewController().listen(controller) {blockID in
                expectation.fulfill()
            }
            self.waitForExpectations()
        }
        
        let pageEvents = tracker.observedEvents.flatMap {(e : AnyObject) -> [OEXMockAnalyticsEventRecord] in
            if let event = e as? OEXMockAnalyticsEventRecord where event.event.name == OEXAnalyticsEventComponentViewed {
                return [event]
            }
            else {
                return []
            }
        }
        
        XCTAssertEqual(pageEvents.count, childIDs.count)
        for (blockID, event) in zip(childIDs, pageEvents) {
            XCTAssertEqual(blockID, event.properties[OEXAnalyticsKeyBlockID] as? String)
            XCTAssertEqual(outline.root, event.properties[OEXAnalyticsKeyCourseID] as? CourseBlockID)
            XCTAssertEqual(event.event.name, OEXAnalyticsEventComponentViewed)
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
    
    func testOpenOnWebEnabling() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren()
        let childIDs = outline.blocks[parent]!.children

        for childID in childIDs {
            loadAndVerifyControllerWithInitialChild(childID, parentID: parent, verifier: { (couseBlockID:CourseBlockID?, vc : CourseContentPageViewController) -> Void in
                let currentBlock = self.outline.blocks[childID]!
                let hasURL = currentBlock.webURL != nil
                XCTAssertTrue(hasURL == vc.t_isRightBarButtonEnabled, "Mismatch between URL validity and button state")
            })

            }
        }
        
    }
