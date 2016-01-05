//
//  Array+FunctionalTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest
@testable import edX

class Array_FunctionalTests: XCTestCase {
    
    func testMapOrNilSuccess() {
        let list = [1, 2, 3]
        let result = list.mapOrFailIfNil {
            return $0 + 1
        }
        XCTAssertEqual([2, 3, 4], result!)
    }
    
    func testMapOrNilFailure() {
        let list = [1, 2, 3]
        let result = list.mapOrFailIfNil { i -> Int? in
            if i == 1 {
                return nil
            }
            else {
                return i + 1
            }
        }
        XCTAssertNil(result)
    }
    
    func testMapSkippingNil() {
        let list = [1, 2, 3]
        let result = list.mapSkippingNils {i -> Int? in
            if i == 2 {
                return nil
            }
            else {
                return i + 1
            }
        }
        XCTAssertEqual(result, [2, 4])
    }

    func testFirstIndexMatchingSuccess() {
        let list = [1, 2, 3, 2, 4]
        let i = list.firstIndexMatching({$0 == 2})
        XCTAssertEqual(1, i!)
    }
    
    func testFirstIndexMatchingFailure() {
        let list = [1, 2, 3, 2, 4]
        let i = list.firstIndexMatching({$0 == 10})
        XCTAssertNil(i)
    }

    func testWithItemIndexes() {
        let list = ["a", "b", "c"]
        let result = list.withItemIndexes()
        XCTAssertEqual(result.count, list.count)
        for i in 0 ..< list.count {
            XCTAssertEqual(list[i], result[i].value)
            XCTAssertEqual(i, result[i].index)
        }
    }
    
    func testInterposeExpected() {
        let list = [1, 2, 3]
        let result = list.interpose({ 10 })
        XCTAssertEqual(result, [1, 10, 2, 10, 3])
    }
    
    func testInterposeNewItem() {
        let list = [1, 2, 3]
        var counter = 10
        let result = list.interpose {
            counter = counter + 1
            return counter
        }
        XCTAssertEqual(result, [1, 11, 2, 12, 3])
    }
}
