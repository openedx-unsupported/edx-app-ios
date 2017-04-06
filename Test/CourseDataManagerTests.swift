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
    
    func checkOutlineLoadsWithQuerier(_ querier : CourseOutlineQuerier, rootID : CourseBlockID, line : UInt = #line, file : StaticString = #file) {
        let rootStream = querier.blockWithID(id: nil)
        let expectation = self.expectation(description: "Outline loads from network")
        rootStream.listenOnce(self) {rootBlock in
            XCTAssertEqual(rootBlock.value!.blockID, rootID, file : file, line : line)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func addInterceptorForOutline(_ networkManager: MockNetworkManager, outline : CourseOutline) {
        networkManager.interceptWhenMatching({_ in true}, successResponse: {
            return (Data(), outline)
        })
    }
    
    func loadAndVerifyOutline() -> TestRouterEnvironment {
        let environment = TestRouterEnvironment()
        addInterceptorForOutline(environment.mockNetworkManager, outline: outline)
        let querier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: outline.root)
        checkOutlineLoadsWithQuerier(querier, rootID: outline.root)
        return environment
    }
    
    func testQuerierCaches() {
        let environment = loadAndVerifyOutline()

        // Now remove network interception
        environment.mockNetworkManager.reset()
        
        // The course should still load since the querier saves it
        let querier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: outline.root)
        checkOutlineLoadsWithQuerier(querier, rootID: outline.root)
    }
    
    func testQuerierClearedOnSignOut() {
        let environment = loadAndVerifyOutline()
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        
        let session = OEXSession(credentialStore: OEXMockCredentialStorage())
        // Close session so the course data should be cleared
        session.closeAndClear()
        environment.mockNetworkManager.reset()
        
        let querier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: outline.root)
        let newOutline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
        addInterceptorForOutline(environment.mockNetworkManager, outline: newOutline)
        checkOutlineLoadsWithQuerier(querier, rootID: newOutline.root)
        XCTAssertNotEqual(newOutline.root, outline.root, "Fresh Courses should be distinct")
        
        defaultsMockRemover.remove()
    }

}
