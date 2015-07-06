//
//  CourseDataManagerTests.swift
//  edX
//
//  Created by Akiva Leffert on 7/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class CourseDataManagerTests: XCTestCase {
    
    let networkManager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string : "http://example.com")!)
    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    
    override func tearDown() {
        networkManager.reset()
    }
    
    func checkOutlineLoadsWithQuerier(querier : CourseOutlineQuerier, rootID : CourseBlockID, line : UInt = __LINE__, file : String = __FILE__) {
        let rootStream = querier.blockWithID(nil)
        let expectation = self.expectationWithDescription("Outline loads from network")
        rootStream.listenOnce(self) {rootBlock in
            XCTAssertEqual(rootBlock.value!.blockID, rootID, file : file, line : line)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func addInterceptorForOutline(outline : CourseOutline) {
        networkManager.interceptWhenMatching({_ in true}, successResponse: {
            return (NSData(), outline)
        })
    }
    
    func loadAndVerifyOutline() -> CourseDataManager {
        let manager = CourseDataManager(interface: nil, networkManager: networkManager)
        addInterceptorForOutline(outline)
        var querier = manager.querierForCourseWithID(outline.root)
        checkOutlineLoadsWithQuerier(querier, rootID: outline.root)
        return manager
    }
    
    func testQuerierCaches() {
        let manager = loadAndVerifyOutline()

        // Now remove network interception
        networkManager.reset()
        
        // The course should still load since the querier saves it
        let querier = manager.querierForCourseWithID(outline.root)
        checkOutlineLoadsWithQuerier(querier, rootID: outline.root)
    }
    
    func testQuerierClearedOnSignOut() {
        let manager = loadAndVerifyOutline()
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        
        let session = OEXSession(credentialStore: OEXMockCredentialStorage())
        // Close session so the course data should be cleared
        session.closeAndClearSession()
        networkManager.reset()
        
        let querier = manager.querierForCourseWithID(outline.root)
        let newOutline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
        addInterceptorForOutline(newOutline)
        checkOutlineLoadsWithQuerier(querier, rootID: newOutline.root)
        XCTAssertNotEqual(newOutline.root, outline.root, "Fresh Courses should be distinct")
        
        defaultsMockRemover.remove()
    }
}
