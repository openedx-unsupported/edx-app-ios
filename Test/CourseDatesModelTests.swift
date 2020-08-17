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
    func testDatesIsInToday() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else { return }
        var blocks = courseDates.courseDateBlocks
        
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
    
    func testDatesIsInPast() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates in past Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.isInPast }
        XCTAssert(blocks.count > 0, "Expected Course Dates in past")
    }
    
    func testDatesIsInFuture() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates in future Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.isInFuture }
        XCTAssert(blocks.count > 0, "Expected Course Dates in future")
    }
    
    func testDatesIsPastDue() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates is Past Due Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.blockStatus == .pastDue }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Past Due")
    }
    
    func testDatesIsDueNext() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates is Due Next Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.blockStatus == .dueNext }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Due Next")
    }
    
    func testDatesLearnerHasAccess() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates Learner Has Access Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.learnerHasAccess }
        XCTAssert(blocks.count > 0, "Expected Course Dates Learner Has Access")
    }
    
    func testDatesShowLink() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates Show Link Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.showLink }
        XCTAssert(blocks.count > 0, "Expected Course Dates Show Link")
    }
    
    func testDatesUnreleased() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates Unreleased Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.isUnreleased }
        XCTAssert(blocks.count > 0, "Expected Course Dates Unreleased")
    }
    
    func testDatesIsReleased() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates Released Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { !$0.isUnreleased }
        XCTAssert(blocks.count > 0, "Expected Course Dates Released")
    }
    
    func testDatesIsAvailable() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates is Available Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.available }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Available")
    }
    
    func testDatesIsAssignment() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else  {
            XCTFail("Expected Course Dates is Assignment Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.isAssignment }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Assignment")
    }
    
    func testDatesIsLearnerAssignment() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else  {
            XCTFail("Expected Course Dates Learner has Access and is Assignment Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.isLearnerAssignment }
        XCTAssert(blocks.count > 0, "Expected Course Dates Learner has Access and is Assignment")
    }
    
    func testDatesHasDescription() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates Has Description Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { $0.hasDescription }
        XCTAssert(blocks.count > 0, "Expected Course Dates Has Description")
    }
    
    func testDatesIsVerifiedOnly() {
        guard let courseDates = CourseDateModel(json: JSON(resourceNamed: "CourseDates")) else {
            XCTFail("Expected Course Dates is Verified Only Failed")
            return
        }
        let blocks = courseDates.courseDateBlocks.filter { !$0.isLearnerAssignment }
        XCTAssert(blocks.count > 0, "Expected Course Dates is Verified Only")
    }
}
