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
        let cursor = ListCursor(list: list, index: 0)
        var acc = [cursor.current!]
        while let value = cursor.next() {
            acc.append(value)
            XCTAssertEqual(value, cursor.current!)
            XCTAssertEqual(cursor.peekPrev()!, acc.last!)
        }
        XCTAssertEqual(acc, list)
        XCTAssertTrue(cursor.hasPrev)
        XCTAssertFalse(cursor.hasNext)
        XCTAssertNil(cursor.next())
    }
    
    
    func testReverseIteration() {
        let cursor = ListCursor(list: list, index: list.count - 1)
        var acc = [cursor.current!]
        while let value = cursor.prev() {
            acc.append(value)
            XCTAssertEqual(value, cursor.current!)
            XCTAssertEqual(cursor.peekNext()!, acc.last!)
        }
        XCTAssertEqual(acc.reverse(), list)
        XCTAssertTrue(cursor.hasNext)
        XCTAssertFalse(cursor.hasPrev)
        XCTAssertNil(cursor.prev())
    }
    
    func testNextPrev() {
        let cursor = ListCursor(list: list, index: 2)
        let original = cursor.current
        let a = cursor.next()
        let b = cursor.prev()
        let c = cursor.next()
        XCTAssertEqual(a!, c!)
        XCTAssertEqual(b!, original!)
        XCTAssertEqual(c!, cursor.current!)
    }

}
