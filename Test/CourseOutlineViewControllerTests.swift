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
    var environment : TestRouterEnvironment!
    let lastAccessedItem = CourseOutlineTestDataFactory.knownLastAccessedItem()
    let networkManager = MockNetworkManager(baseURL: URL(string: "www.example.com")!)
    
    override func setUp() {
        super.setUp()
        environment = TestRouterEnvironment()
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        router = OEXRouter(environment: environment)
    }
    
    func loadAndVerifyControllerWithBlockID(_ blockID : CourseBlockID, verifier : @escaping (CourseOutlineViewController) -> ((XCTestExpectation) -> Void)?) {
        
        let blockIdOrNilIfRoot : CourseBlockID? = blockID == outline.root ? nil : blockID
        let controller = CourseOutlineViewController(environment: environment, courseID: outline.root, rootID: blockIdOrNilIfRoot)
        
        let expectations = self.expectation(description: "course loaded")
        let updateStream = BackedStream<Void>()
        
        inScreenNavigationContext(controller) {
            DispatchQueue.main.async {
                let blockLoadedStream = controller.t_setup()
                updateStream.backWithStream(blockLoadedStream)
                updateStream.listen(controller) {[weak controller] _ in
                    updateStream.removeAllBackings()
                    if let next = controller.flatMap({ verifier($0) }) {
                        next(expectations)
                    }
                    else {
                        expectations.fulfill()
                    }
                }
            }
            self.waitForExpectations()
        }
    }
    
    func testScreenAnalyticsRoot() {
        loadAndVerifyControllerWithBlockID(outline.root) {_ in
            return {expectation -> Void in
                self.environment.eventTracker.eventStream.listenOnce(self) {_ in
                    XCTAssertEqual(self.environment.eventTracker.events.count, 1)
                    let event = self.environment.eventTracker.events.first!.asScreen
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
                self.environment.eventTracker.eventStream.listenOnce(self) {_ in
                    let event = self.environment.eventTracker.events.first!.asScreen
                    XCTAssertNotNil(event)
                    XCTAssertEqual(event!.screenName, OEXAnalyticsScreenSectionOutline)
                    XCTAssertEqual(event!.courseID, self.outline.root)
                    XCTAssertEqual(event!.value, section.internalName)
                    expectation.fulfill()
                }
            }
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
