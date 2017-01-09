//
//  CourseOutlineQuerierTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class CourseOutlineQuerierTests: XCTestCase {
    
    let courseID = OEXCourse.freshCourse().course_id!
    
    func testBlockLoadsFromNetwork() {
        let outline = CourseOutlineTestDataFactory.freshCourseOutline(courseID)
        let networkManager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string : "http://www.example.com")!)
        networkManager.interceptWhenMatching({_ in true}, successResponse: {
            return (nil, outline)
        })
        let querier = CourseOutlineQuerier(courseID: "course", interface: nil, enrollmentManager: nil, networkManager: networkManager, session : nil)
        
        let blockID = CourseOutlineTestDataFactory.knownSection()
        let blockStream = querier.blockWithID(blockID)
        let expectation = expectationWithDescription("block loads")
        let removable = blockStream.listen(self) {block in
            XCTAssertEqual(block.value!.blockID, blockID)
            expectation.fulfill()
        }
        waitForExpectations()
        removable.remove()
    }
    
    func testFlatMap() {
        let outline = CourseOutlineTestDataFactory.freshCourseOutline(courseID)
        let querier = CourseOutlineQuerier(courseID: courseID, outline: outline)
        let knownNodes = CourseOutlineTestDataFactory.knownHTMLBlockIDs()
        let htmlNodeStream = querier.flatMapRootedAtBlockWithID(outline.root) {block -> CourseBlockID? in
            switch block.type {
            case .HTML: return block.blockID
            default: return nil
            }
        }
        let expectation = expectationWithDescription("Map Finished")
        let removable = htmlNodeStream.listen(self) {blocks in
            XCTAssertEqual(Set(blocks.value!), Set(knownNodes))
            expectation.fulfill()
        }
        waitForExpectations()
        removable.remove()
    }
    
    func testDepthQuerierSiblings() {
        let outline = CourseOutlineTestDataFactory.freshCourseOutline(courseID)
        let querier = CourseOutlineQuerier(courseID: courseID, outline: outline)
        let root = outline.blocks[outline.root]!
        let child = root.children[1]
        let cursor = querier.spanningCursorForBlockWithID(outline.root, initialChildID : child).value!
        
        let block = cursor.prev()!.block
        XCTAssertEqual(root.children[0], block.blockID)
        var i = 1
        while let group = cursor.next() {
            XCTAssertEqual(root.children[i], group.block.blockID)
            i = i + 1
        }
    }
    
    func testDepthQuerierFirstChild() {
        let outline = CourseOutlineTestDataFactory.freshCourseOutline(courseID)
        let querier = CourseOutlineQuerier(courseID: courseID, outline: outline)
        let root = outline.blocks[outline.root]!
        let cursor = querier.spanningCursorForBlockWithID(outline.root, initialChildID: nil).value!
        
        XCTAssertFalse(cursor.hasPrev)
        let block = cursor.next()!.block
        XCTAssertEqual(root.children[1], block.blockID)
        var i = 2
        while let group = cursor.next() {
            XCTAssertEqual(root.children[i], group.block.blockID)
            i = i + 1
        }
    }
    
    func testReloadsAfterFailure() {
        let networkManager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string : "http://www.example.com")!)
        let querier = CourseOutlineQuerier(courseID: courseID, interface: nil, enrollmentManager: nil, networkManager: networkManager, session : nil)
        let blockID = CourseOutlineTestDataFactory.knownSection()
        
        // attempt to load a block but there's no outline in network or cache so it should fail
        var blockStream = querier.blockWithID(blockID)
        var expectation = expectationWithDescription("block fails to load")
        var removable = blockStream.listen(self) {[weak blockStream] result in
            XCTAssertTrue(result.isFailure)
            if !(blockStream?.active ?? false) {
                expectation.fulfill()
            }
        }
        waitForExpectations()
        removable.remove()
        
        // now if we supply a loadable outline
        let outline = CourseOutlineTestDataFactory.freshCourseOutline(courseID)
        networkManager.interceptWhenMatching({_ in true}) {
            return (nil, outline)
        }
        
        expectation = expectationWithDescription("block loads")
        
        // the stream should now have the newly available outline so a fresh request should succeed
        blockStream = querier.blockWithID(blockID)
        removable = blockStream.listen(self) {
            if let value = $0.value {
                XCTAssertEqual(value.blockID, blockID)
                expectation.fulfill()
            }
        }
        waitForExpectations()
        removable.remove()
        
    }
    
    func testMissingChildFilteredOut() {
        let outline = CourseOutline(root: "root", blocks:
            [
                "root": CourseBlock(type: CourseBlockType.Section,
                    children: ["found", "missing"], blockID: "root", minifiedBlockID: "123456", name: "Root!", multiDevice: true),
                "found": CourseBlock(type: CourseBlockType.Section,
                    children: [], blockID: "found", minifiedBlockID: "123456", name: "Child!", multiDevice: true)
            ]
        )
        let querier = CourseOutlineQuerier(courseID: courseID, outline: outline)
        let childStream = querier.childrenOfBlockWithID(nil)
        childStream.listenOnce(self) {
            XCTAssertEqual($0.value!.children.count, 1)
            XCTAssertEqual($0.value!.children[0].blockID, "found")
        }
        waitForStream(childStream)
    }
}
