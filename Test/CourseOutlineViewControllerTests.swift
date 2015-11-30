//
//  CourseOutlineViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
@testable import edX

class CourseOutlineViewControllerTests: SnapshotTestCase {
    
    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var router : OEXRouter!
    var environment : CourseOutlineViewController.Environment!
    var courseDataManager : MockCourseDataManager!
    let lastAccessedItem = CourseOutlineTestDataFactory.knownLastAccessedItem()
    let networkManager = MockNetworkManager(baseURL: NSURL(string: "www.example.com")!)
    var tracker : MockAnalyticsTracker!
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        courseDataManager = MockCourseDataManager(querier: querier)
        let dataManager = DataManager(courseDataManager: courseDataManager)
        let analytics = OEXAnalytics()
        tracker = MockAnalyticsTracker()
        analytics.addTracker(tracker)
        
        let routerEnvironment = RouterEnvironment(analytics : analytics, config : OEXConfig(), dataManager : dataManager, interface : nil, networkManager : networkManager, session : OEXSession(), styles : OEXStyles())
        
        router = OEXRouter(environment: routerEnvironment)
        environment = CourseOutlineViewController.Environment(
            analytics: analytics,
            dataManager : dataManager,
            networkManager: networkManager,
            reachability : MockReachability(),
            router : router,
            styles : routerEnvironment.styles)
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
                    updateStream.removeAllBackings()
                    if let next = controller.flatMap({ verifier($0) }) {
                        next(expectation)
                    }
                    else {
                        expectation.fulfill()
                    }
                }
            }
            self.waitForExpectations()
        }
    }
    
    func testVideoModeSwitches() {
        // First ensure that there are non video sections that will be filtered
        let querier = courseDataManager.querierForCourseWithID("anything")
        let fullChildren = querier.childrenOfBlockWithID(outline.root, forMode: .Full)
        let filteredChildren = querier.childrenOfBlockWithID(outline.root, forMode: .Video)
        
        let expectation = expectationWithDescription("Loaded children")
        let stream = joinStreams(fullChildren, filteredChildren)
        stream.listen(NSObject()) {
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
    
    func testScreenAnalyticsRoot() {
        loadAndVerifyControllerWithBlockID(outline.root) {_ in
            return {expectation -> Void in
                self.tracker.eventStream.listenOnce(self) {_ in
                    XCTAssertEqual(self.tracker.events.count, 1)
                    let event = self.tracker.events.first!.asScreen
                    XCTAssertNotNil(event)
                    XCTAssertEqual(event!.screenName, OEXAnalyticsScreenCourseOutline)
                    XCTAssertEqual(event!.courseID, self.outline.root)
                    XCTAssertNil(event!.value)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func testScreenAnalyticsChild() {
        let sectionID = CourseOutlineTestDataFactory.knownSection()
        let section = outline.blocks[sectionID]!
        loadAndVerifyControllerWithBlockID(section.blockID) {_ in
            return {expectation -> Void in
                self.tracker.eventStream.listenOnce(self) {_ in
                    let event = self.tracker.events.first!.asScreen
                    XCTAssertNotNil(event)
                    XCTAssertEqual(event!.screenName, OEXAnalyticsScreenSectionOutline)
                    XCTAssertEqual(event!.courseID, self.outline.root)
                    XCTAssertEqual(event!.value, section.internalName)
                    expectation.fulfill()
                }
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
