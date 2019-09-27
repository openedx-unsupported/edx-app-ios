//
//  UserAgentGenerationOperation.swift
//  edX
//
//  Created by Akiva Leffert on 12/10/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX

class UserAgentGenerationOperationTests : XCTestCase {
    func testLoadBasic() {
        let queue = OperationQueue()
        let operation = UserAgentGenerationOperation()
        queue.addOperation(operation)
        waitForStream(operation.t_resultStream) {
            let agent = $0.value!
            // Random part of the standard user agent string, to make sure we got something
            XCTAssertTrue(agent.contains("KHTML, like Gecko"))
        }
    }
    
    func testOverride() {
        let userDefaults = OEXMockUserDefaults()
        let userDefaultsMock = userDefaults.installAsStandardUserDefaults()
        let expectation = self.expectation(description: "User agent overriden")
        UserAgentOverrideOperation.overrideUserAgent {
            expectation.fulfill()
        }
        waitForExpectations()
        
        let queue = OperationQueue()
        let operation = UserAgentGenerationOperation()
        queue.addOperation(operation)
        waitForStream(operation.t_resultStream) {
            let agent = $0.value!
            // Random part of the standard user agent string, to make sure we got something
            XCTAssertTrue(agent.contains(UserAgentGenerationOperation.appVersionDescriptor))
        }

        userDefaultsMock.remove()
    }
}
