//
//  DiscussionResponsesViewControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 4/25/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
@testable import edX

class DiscussionResponsesViewControllerTests: XCTestCase {
 
    func testAddResponse() {
        var thread = DiscussionTestsDataFactory.thread
        let endorsedResponses = DiscussionTestsDataFactory.endorsedResponses()
        var unendorsedResponses = DiscussionTestsDataFactory.unendorsedResponses()
        
        thread.responseCount = endorsedResponses.count + unendorsedResponses.count
        
        let unendorsedResponse = DiscussionTestsDataFactory.unendorsedComment
        
        unendorsedResponses.append(unendorsedResponse)
        
        let responseCount = thread.responseCount ?? 0
        thread.responseCount = responseCount + 1
        
        XCTAssertEqual(thread.responseCount, endorsedResponses.count + unendorsedResponses.count)
        
    }
}
