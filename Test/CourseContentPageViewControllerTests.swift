//
//  CourseContentPageViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
@testable import edX

class CourseContentPageViewControllerTests: SnapshotTestCase {
    
    var course : OEXCourse!
    var outline : CourseOutline!
    var router : OEXRouter!
    var environment : TestRouterEnvironment!
    let networkManager = MockNetworkManager(baseURL: URL(string: "www.example.com")!)
    
    override func setUp() {
        super.setUp()
        course = OEXCourse.freshCourse()
        outline = CourseOutlineTestDataFactory.freshCourseOutline(course.course_id!)
        let interface = OEXInterface.shared()
        interface.t_setCourseEnrollments([UserCourseEnrollment(course: course)])
        interface.t_setCourseVideos([course.video_outline!: OEXVideoSummaryTestDataFactory.localCourseVideos(CourseOutlineTestDataFactory.knownLocalVideoID)])
        environment = TestRouterEnvironment(config: OEXConfig(dictionary:["TAB_LAYOUTS_ENABLED": true]), interface: interface)
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: course.course_id!, interface: interface, outline: outline)
        router = OEXRouter(environment: environment)
    }
    
    @discardableResult func loadAndVerifyControllerWithInitialChild(_ initialChildID : CourseBlockID?, parentID : CourseBlockID, verifier : ((CourseBlockID?, CourseContentPageViewController) -> ((XCTestExpectation) -> Void)?)? = nil) -> CourseContentPageViewController {
        
        let controller = CourseContentPageViewController(environment: environment, courseID: outline.root, rootID: parentID, initialChildID: initialChildID, forMode: .full)
        
        inScreenNavigationContext(controller) {
            let expectation = self.expectation(description: "course loaded")
            DispatchQueue.main.async() {
                let blockLoadedStream = controller.t_blockIDForCurrentViewController()
                blockLoadedStream.listen(controller) {blockID in
                    if let next = verifier?(blockID.value, controller) {
                        next(expectation)
                    }
                    else {
                        expectation.fulfill()
                    }
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
            return nil
        }
    }

    func testShowsRequestedChild() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 1, "Need at least two children for this test")
        let childID = childIDs.last
        
        loadAndVerifyControllerWithInitialChild(childID, parentID: parent) { (blockID, _) in
            XCTAssertEqual(childID!, blockID!)
            return nil
        }
    }
    
    func testInvalidRequestedChild() {
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 1, "Need at least two children for this test")
        let childID = childIDs.first
        
        loadAndVerifyControllerWithInitialChild("invalid child id", parentID: parent) { (blockID, _) in
            XCTAssertEqual(childID!, blockID!)
            return nil
        }
    }
    
    func testNextButton() {
        let childIDs = outline.blocks[outline.root]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.first
        
        let controller = loadAndVerifyControllerWithInitialChild(childID, parentID: outline.root) { (_, controller) in
            XCTAssertFalse(controller.t_prevButtonEnabled, "First child shouldn't have previous button enabled")
            XCTAssertTrue(controller.t_nextButtonEnabled, "First child should have next button enabled")
            return nil
        }
        
        // Traverse through the entire child list going forward
        // verifying that we're viewing the right thing
        for childID in childIDs[1 ..< childIDs.count] {
            controller.t_goForward()
            
            let testExpectation = expectation(description: "controller went forward")
            DispatchQueue.main.async() {
                controller.t_blockIDForCurrentViewController().listen(controller) {
                    testExpectation.fulfill()
                    XCTAssertEqual($0.value!, childID)
                }
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
            return nil
        }
        
        // Traverse through the entire child list going backward
        // verifying that we're viewing the right thing
        for _ in Array(childIDs.reversed())[1 ..< childIDs.count] {
            controller.t_goBackward()
            
            let testExpectation = expectation(description: "controller went backward")
            controller.t_blockIDForCurrentViewController().listen(controller) {blockID in
                testExpectation.fulfill()
            }
            self.waitForExpectations()
        }
    }
    
    func testScreenAnalyticsEmitted() {
        let childIDs = outline.blocks[outline.root]!.children
        XCTAssertTrue(childIDs.count > 2, "Need at least three children for this test")
        let childID = childIDs.first
        
        loadAndVerifyControllerWithInitialChild(childID, parentID: outline.root) {_ in
            return { expectation -> Void in
                DispatchQueue.main.async {
                    self.environment.eventTracker.eventStream.listenOnce(self) {_ in
                        let events = self.environment.eventTracker.events.flatMap { return $0.asScreen }
                        
                        if events.count < 2 {
                            return
                        }
                        
                        let event = events.first!
                        XCTAssertNotNil(event)
                        XCTAssertEqual(event.screenName, OEXAnalyticsScreenUnitDetail)
                        XCTAssertEqual(event.courseID, self.outline.root)
                        XCTAssertEqual(event.value, self.outline.blocks[self.outline.root]?.internalName)
                        expectation.fulfill()
                    }
                }
            }
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
            
            let testExpectation = expectation(description: "controller went backward")
            DispatchQueue.main.async() {
                controller.t_blockIDForCurrentViewController().listen(controller) {blockID in
                    testExpectation.fulfill()
                }
            }
            self.waitForExpectations()
        }
        
        let pageEvents = environment.eventTracker.events.flatMap {(e : MockAnalyticsRecord) -> MockAnalyticsEventRecord? in
            if let event = e.asEvent, event.event.name == OEXAnalyticsEventComponentViewed {
                return event
            }
            else {
                return nil
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
        let parent : CourseBlockID = CourseOutlineTestDataFactory.knownParentIDWithMultipleChildren
        let childIDs = outline.blocks[parent]!.children
        XCTAssertTrue(childIDs.count > 1, "Need at least two children for this test")
        let childID = childIDs.last
        
        loadAndVerifyControllerWithInitialChild(childID, parentID: parent) { (blockID, controller) in
            self.assertSnapshotValidWithContent(controller.navigationController!)
            return nil
        }
    }
}
