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
    
    func testAddResponseIncreasesParentCount() {
        
        let thread = DiscussionTestsDataFactory.thread
        
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.thread = thread
        
        let responseCount = responsesViewController.thread!.responseCount!
        
        responsesViewController.increaseResponseCount()
        
        let updatedResponseCount = responsesViewController.thread?.responseCount
        
        XCTAssertEqual(responseCount + 1, updatedResponseCount)
        
    }
}
