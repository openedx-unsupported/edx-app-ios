//
//  ListCursorTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class ListCursorTests: XCTestCase {
    
    let list = [1, 2, 3, 4, 5]
    
    func testForwardIteration() {
        let cursor = ListCursor(startOfList: list)!
        var acc = [cursor.current]
        while let value = cursor.next() {
            acc.append(value)
            XCTAssertEqual(value, cursor.current)
        }
        XCTAssertEqual(acc, list)
        XCTAssertTrue(cursor.hasPrev)
        XCTAssertFalse(cursor.hasNext)
        XCTAssertNil(cursor.next())
    }
    
    
    func testReverseIteration() {
        let cursor = ListCursor(endOfList: list)!
        var acc = [cursor.current]
        while let value = cursor.prev() {
            acc.append(value)
            XCTAssertEqual(value, cursor.current)
        }
        XCTAssertEqual(Array(acc.reversed()), list)
        XCTAssertTrue(cursor.hasNext)
        XCTAssertFalse(cursor.hasPrev)
        XCTAssertNil(cursor.prev())
    }
    
    func testNextPrev() {
        let cursor = ListCursor(before: [1, 2], current: 3, after: [4, 5])
        let original = cursor.current
        let a = cursor.next()
        XCTAssertEqual(cursor.peekPrev()!, original)
        let b = cursor.prev()
        XCTAssertEqual(cursor.peekNext()!, a!)
        let c = cursor.next()
        XCTAssertEqual(a!, c!)
        XCTAssertEqual(b!, original)
        XCTAssertEqual(c!, cursor.current)
    }
    
    func testStartEmpty() {
        let startCursor = ListCursor<Int>(startOfList: [])
        XCTAssertNil(startCursor)
        
        let endCursor = ListCursor<Int>(endOfList:[])
        XCTAssertNil(endCursor)
    }
    
    func testCurrentPredicateFound() {
        let cursor = ListCursor(list: list, currentFinder: { $0 == 3 })
        XCTAssertNotNil(cursor)
        XCTAssertEqual(cursor!.current, 3)
    }
    
    func testCurrentPredicateFailed() {
        let cursor = ListCursor(list: list, currentFinder: { $0 == 10 })
        XCTAssertNil(cursor)
    }

    func testLoopToBeginning() {
        var acc : [Int] = []
        let cursor = ListCursor(before: [1, 2], current: 3, after: [4, 5])
        cursor.loopToStart {(cursor, _) in
            acc.insert(cursor.current, at: 0)
        }
        XCTAssertEqual(acc, [1, 2, 3])
    }
    
    func testLoopToBeginningExclusive() {
        var acc : [Int] = []
        let cursor = ListCursor(before: [1, 2], current: 3, after: [4, 5])
        cursor.loopToStartExcludingCurrent {(cursor, _) in
            acc.insert(cursor.current, at: 0)
        }
        XCTAssertEqual(acc, [1, 2])
    }
    
    func testLoopToEnd() {
        var acc : [Int] = []
        let cursor = ListCursor(before: [1, 2], current: 3, after: [4, 5])
        cursor.loopToEnd {(cursor, _) in
            acc.append(cursor.current)
        }
        XCTAssertEqual(acc, [3, 4, 5])
    }
    
    func testLoopToEndExclusive() {
        var acc : [Int] = []
        let cursor = ListCursor(before: [1, 2], current: 3, after: [4, 5])
        cursor.loopToEndExcludingCurrent {(cursor, _) in
            acc.append(cursor.current)
        }
        XCTAssertEqual(acc, [4, 5])
    }
}
