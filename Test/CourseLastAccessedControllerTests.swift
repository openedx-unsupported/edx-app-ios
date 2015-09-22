//
//  CourseLastAccessedControllerTests.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 06/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
import edX


class MockLastAccessedDelegate : CourseLastAccessedControllerDelegate {
    var didFetchAction : (CourseLastAccessed? -> Void)?
    func courseLastAccessedControllerDidFetchLastAccessedItem(item: CourseLastAccessed?) {
        didFetchAction?(item)
    }
}


class CourseLastAccessedControllerTests: SnapshotTestCase {

    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var courseDataManager : MockCourseDataManager!
    
    var lastAccessedItem = CourseOutlineTestDataFactory.knownLastAccessedItem()
    let networkManager = MockNetworkManager(baseURL: NSURL(string: "www.example.com")!)
    let lastAccessedProvider = MockLastAccessedProvider()
    
    var rootController : CourseLastAccessedController?
    var sectionController : CourseLastAccessedController?
    var nonVideoSectionController : CourseLastAccessedController?
    
    override func setUp() {
        super.setUp()
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        courseDataManager = MockCourseDataManager(querier: querier)
        let dataManager = DataManager(courseDataManager: courseDataManager)
        
        networkManager.interceptWhenMatching({_ in return true}, successResponse: { () -> (NSData?,CourseLastAccessed) in
            return (nil, self.lastAccessedItem)
        })
        
        rootController = CourseLastAccessedController(blockID: nil,
            dataManager: dataManager,
            networkManager: networkManager,
            courseQuerier: querier,
            lastAccessedProvider : lastAccessedProvider)
        
        sectionController = CourseLastAccessedController(blockID: "unit3",
            dataManager: dataManager,
            networkManager: networkManager,
            courseQuerier: querier,
            lastAccessedProvider: lastAccessedProvider)
        
        nonVideoSectionController = CourseLastAccessedController(blockID: "unit1",
            dataManager: dataManager,
            networkManager: networkManager,
            courseQuerier: querier,
            lastAccessedProvider: lastAccessedProvider)
    }
    
    func testLastAccessedItemRecieved() {
        self.lastAccessedItem = CourseLastAccessed(moduleId: "unit3", moduleName: "Unit 3")
        let delegate = MockLastAccessedDelegate()
        rootController?.delegate = delegate
        sectionController?.saveLastAccessed()
        rootController?.loadLastAccessed(forMode: .Full)
        let expectation = self.expectationWithDescription("Item Fetched")
        delegate.didFetchAction = { item in
            if item?.moduleName == "Unit 3" {
                expectation.fulfill()
            }
        }
        self.waitForExpectations()
    }
    
    func testSetLastAccessedItem() {
        let delegate = MockLastAccessedDelegate()
        rootController?.delegate = delegate

        self.lastAccessedItem = CourseLastAccessed(moduleId: "unit3", moduleName: "Unit 3")
        
        sectionController?.saveLastAccessed()
        let expectation = self.expectationWithDescription("Set Last Accessed to Unit 3")
        rootController?.loadLastAccessed(forMode: .Full)
        delegate.didFetchAction = { item in
            if (item?.moduleName == "Unit 3") {
                expectation.fulfill()
            }
        }
        self.waitForExpectations()
    }
    
    
    func testModeVideo() {
        let delegate = MockLastAccessedDelegate()
        rootController?.delegate = delegate
        
        let expectation = self.expectationWithDescription("Unit 1 should return nil")
        
        self.lastAccessedItem = CourseLastAccessed(moduleId: "unit1", moduleName: "Unit 1")
        nonVideoSectionController?.saveLastAccessed()
        delegate.didFetchAction = { item in
            if (item?.moduleName == nil) {
                expectation.fulfill()
            }
        }
        rootController?.loadLastAccessed(forMode: .Video)
        self.waitForExpectations()
    }
    
    override func tearDown() {
        super.tearDown()
        networkManager.reset()
        lastAccessedProvider.resetLastAccessedItem()
    }
}
