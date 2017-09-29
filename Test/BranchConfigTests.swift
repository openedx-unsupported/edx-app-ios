//
//  BranchConfigTests.swift
//  edX
//
//  Created by Saeed Bashir on 9/29/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import XCTest
@testable import edX

class BranchConfigTests: XCTestCase{
    func testBranchConfig() {
        let config = BranchConfig(dictionary: ["ENABLED": true, "BRANCH_KEY": "branch_key"])
        
        XCTAssertNotNil(config)
        XCTAssertTrue(config.enabled)
        XCTAssertNotNil(config.branchKey)
    }
    
    func testEmptyBranchConfig() {
        let config = BranchConfig(dictionary: [:])
        
        XCTAssertNotNil(config)
        XCTAssertFalse(config.enabled)
        XCTAssertNil(config.branchKey)
    }
}
