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

class CourseLastAccessedControllerTests: XCTestCase, CourseLastAccessedControllerDelegate {

    let outline = CourseOutlineTestDataFactory.freshCourseOutline(OEXCourse.freshCourse().course_id!)
    var courseDataManager : MockCourseDataManager!
    let lastAccessedItem = CourseOutlineTestDataFactory.knownLastAccessedItem()
    let networkManager = MockNetworkManager(baseURL: NSURL(string: "www.example.com")!)
    
    var itemFetchedExpectation : XCTestExpectation?
    
    var controller : CourseLastAccessedController?
    
    override func setUp() {
        super.setUp()
        let blockID = outline.root
        let querier = CourseOutlineQuerier(courseID: outline.root, outline : outline)
        courseDataManager = MockCourseDataManager(querier: querier)
        let dataManager = DataManager(courseDataManager: courseDataManager)
        
        controller = CourseLastAccessedController(blockID: nil,
            dataManager: dataManager,
            networkManager: networkManager,
            courseQuerier: querier)
        
   
        
//        controller?.delegate = self
    }
    
//    func testLastAccessedItem() {
//        controller?.loadLastAccessed(forMode: .Full)
//        itemFetchedExpectation = expectationWithDescription("Item fetched")
//        self.waitForExpectations(handler: nil)
//        XCTAssert(true, "Passed")
//    }
    
    
    
    
    //DELEGATE
    
    func courseLastAccessedControllerdidFetchLastAccessedItem(item: CourseLastAccessed?) {
//        itemFetchedExpectation?.fulfill()
    }
    
    
}
