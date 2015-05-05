//
//  XCTestCase+Equality.swift
//  edX
//
//  Created by Akiva Leffert on 5/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    func equalAndNotNil<T : Equatable>(@autoclosure expected : () -> T, @autoclosure _ actual : () -> T?) -> Bool {
        let actual = actual()
        let e = expected()
        if let a = actual {
            return e == a
        }
        else {
            return false
        }
    }
    
    func equalAndNotNil<T : Equatable>(@autoclosure expected : () -> [T], @autoclosure _ actual : () -> [T]?) -> Bool {
        let actual = actual()
        let e = expected()
        if let a = actual {
            return e == a
        }
        else {
            return false
        }
    }
}