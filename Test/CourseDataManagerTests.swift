//
//  CourseDataManagerTests.swift
//  edX
//
//  Created by Akiva Leffert on 7/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

@testable import edX
import UIKit
import XCTest

class CourseDataManagerTests: XCTestCase {
    
    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    
    func checkOutlineLoadsWithQuerier(querier : CourseOutlineQuerier, rootID : CourseBlockID, line : UInt = __LINE__, file : String = __FILE__) {
        let rootStream = querier.blockWithID(nil)
        let expectation = self.expectationWithDescription("Outline loads from network")
        rootStream.listenOnce(self) {rootBlock in
            XCTAssertEqual(rootBlock.value!.blockID, rootID, file : file, line : line)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func addInterceptorForOutline(networkManager: MockNetworkManager, outline : CourseOutline) {
        networkManager.interceptWhenMatching({_ in true}, successResponse: {
            return (NSData(), outline)
        })
    }
    
    func loadAndVerifyOutline() -> TestRouterEnvironment {
        let environment = TestRouterEnvironment()
        addInterceptorForOutline(environment.mockNetworkManager, outline: outline)
        let querier = environment.dataManager.courseDataManager.querierForCourseWithID(outline.root)
        checkOutlineLoadsWithQuerier(querier, rootID: outline.root)
        return environment
    }
    
    func testQuerierCaches() {
        let environment = loadAndVerifyOutline()

        // Now remove network interception
        environment.mockNetworkManager.reset()
        
        // The course should still load since the querier saves it
        let querier = environment.dataManager.courseDataManager.querierForCourseWithID(outline.root)
        checkOutlineLoadsWithQuerier(querier, rootID: outline.root)
    }
    
    func testQuerierClearedOnSignOut() {
        let environment = loadAndVerifyOutline()
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        
        let session = OEXSession(credentialStore: OEXMockCredentialStorage())
        // Close session so the course data should be cleared
        session.closeAndClearSession()
        environment.mockNetworkManager.reset()
        
        let querier = environment.dataManager.courseDataManager.querierForCourseWithID(outline.root)
        let newOutline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
        addInterceptorForOutline(environment.mockNetworkManager, outline: newOutline)
        checkOutlineLoadsWithQuerier(querier, rootID: newOutline.root)
        XCTAssertNotEqual(newOutline.root, outline.root, "Fresh Courses should be distinct")
        
        defaultsMockRemover.remove()
    }
    
    func testModeChangedAnalytics() {
        let environment = TestRouterEnvironment()
        // make a real course data manager instead of using the mock one from the environment
        // since that's the thing we're actually testing here
        let courseDataManager = CourseDataManager(analytics: environment.analytics, enrollmentManager: environment.mockEnrollmentManager, interface: nil, networkManager: environment.networkManager, session: environment.session)
        let userDefaults = OEXMockUserDefaults()
        let defaultsMock = userDefaults.installAsStandardUserDefaults()
        
        courseDataManager.currentOutlineMode = .Video
        let videoEvent = environment.eventTracker.events.last!.asEvent!
        XCTAssertEqual(videoEvent.event.name, OEXAnalyticsEventOutlineModeChanged)
        XCTAssertEqual(videoEvent.properties[OEXAnalyticsKeyNavigationMode] as? String, OEXAnalyticsValueNavigationModeVideo)
        XCTAssertEqual(videoEvent.event.category, OEXAnalyticsCategoryNavigation)
        
        courseDataManager.currentOutlineMode = .Full
        let fullEvent = environment.eventTracker.events.last!.asEvent!
        XCTAssertEqual(fullEvent.event.name, OEXAnalyticsEventOutlineModeChanged)
        XCTAssertEqual(fullEvent.properties[OEXAnalyticsKeyNavigationMode] as? String, OEXAnalyticsValueNavigationModeFull)
        XCTAssertEqual(fullEvent.event.category, OEXAnalyticsCategoryNavigation)
        
        defaultsMock.remove()
    }

}
