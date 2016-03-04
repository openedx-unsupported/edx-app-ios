//
//  XCTestCase+Async.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import XCTest
import edX

extension XCTestCase {
    
    // Standardize on a reasonable timeout to account for slow CI systems interacting with slow operations like
    // screenshot generation. Also makes it easier to change to a long number when debugging
    func waitForExpectations(handler : XCWaitCompletionHandler? = nil) {
        waitForExpectationsWithTimeout(15, handler: handler)
    }
        
    func stepRunLoop() {
        let expectation = expectationWithDescription("run loop iterates")
        dispatch_async(dispatch_get_main_queue()) {
            expectation.fulfill()
        }
        waitForExpectations()
    }
}