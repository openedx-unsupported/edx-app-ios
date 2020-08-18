//
//  CourseDatesModelTests.swift
//  edXTests
//
//  Created by Muhammad Umer on 17/08/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import XCTest

@testable import edX

class CourseDatesModelTests: XCTestCase {
    let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates"))
    
    func testCourseDates() {
        guard let _ = courseDates else {
            XCTFail("Expected Course Dates Not Available")
            return
        }
        XCTAssert(true, "Expected Course Dates Available")
    }
    
    func testDatesIsInToday() {
        var blocks = courseDates!.courseDateBlocks
        
        let isToday = blocks.first { $0.blockStatus == .today }
        
        if isToday == nil {
            let past = blocks.filter { $0.isInPast }
            let future = blocks.filter { $0.isInFuture }
            let todayBlock = CourseDateBlock()
            
            blocks.removeAll()
            
            blocks.append(contentsOf: past)
            blocks.append(todayBlock)
            blocks.append(contentsOf: future)
            
            if let _ = blocks.first(where: { $0.blockStatus == .today }) {
                XCTAssert(true, "Expected Course Date in today")
            } else {
                XCTFail("Expected Course Date in Today Failed")
            }
            
        } else {
            XCTAssert(true, "Expected Course Date in today")
        }
    }
    
    func testDatesIsInNotToday() {
        let isToday = courseDates!.courseDateBlocks.first { $0.blockStatus == .today }
        XCTAssert(isToday == nil, "Expected Course Date in Not Today")
    }
    
    func testDatesIsInPast() {
        let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates"))
        let blocks = courseDates!.courseDateBlocks.filter { $0.isInPast }
        XCTAssert(blocks.count > 0, "Expected Course Dates in past")
    }
    
    func testDatesIsInFuture() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.isInFuture }
        XCTAssert(blocks.count > 0, "Expected Course Dates in future")
    }
    
    func testDatesIsPastDue() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.blockStatus == .pastDue }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Past Due")
    }
    
    func testDatesIsDueNext() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.blockStatus == .dueNext }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Due Next")
    }
    
    func testDatesLearnerHasAccess() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.learnerHasAccess }
        XCTAssert(blocks.count > 0, "Expected Course Dates Learner Has Access")
    }
    
    func testDatesShowLink() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.showLink }
        XCTAssert(blocks.count > 0, "Expected Course Dates Show Link")
    }
    
    func testDatesUnreleased() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.isUnreleased }
        XCTAssert(blocks.count > 0, "Expected Course Dates Unreleased")
    }
    
    func testDatesIsReleased() {
        let blocks = courseDates!.courseDateBlocks.filter { !$0.isUnreleased }
        XCTAssert(blocks.count > 0, "Expected Course Dates Released")
    }
    
    func testDatesIsAvailable() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.available }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Available")
    }
    
    func testDatesIsAssignment() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.isAssignment }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Assignment")
    }
    
    func testDatesIsLearnerAssignment() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.isLearnerAssignment }
        XCTAssert(blocks.count > 0, "Expected Course Dates Learner has Access and is Assignment")
    }
    
    func testDatesHasDescription() {
        let blocks = courseDates!.courseDateBlocks.filter { $0.hasDescription }
        XCTAssert(blocks.count > 0, "Expected Course Dates Has Description")
    }
    
    func testDatesIsVerifiedOnly() {
        let blocks = courseDates!.courseDateBlocks.filter { !$0.isLearnerAssignment }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Verified Only")
    }
}
