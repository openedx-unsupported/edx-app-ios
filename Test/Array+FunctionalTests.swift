//
//  Array+FunctionalTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest

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

}
