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
        waitForExpectationsWithTimeout(5, handler: handler)
    }
    
    func waitForStream<A>(stream : Stream<A>, verifier : (Result<A> -> Void)? = nil) {
        let expectation = expectationWithDescription("stream fires")
        stream.extendLifetimeUntilFirstResult {
            verifier?($0)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func verifyInNextRunLoop(action : () -> Void) {
        let expectation = expectationWithDescription("run loop iterates")
        dispatch_async(dispatch_get_main_queue()) {
            action()
            expectation.fulfill()
        }
        waitForExpectations()
    }
}