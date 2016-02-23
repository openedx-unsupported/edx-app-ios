//
//  DiscussionResponsesDataControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 2/25/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX
import Foundation


class DiscussionResponsesDataControllerTests:  XCTestCase {
    
    func testAddChildComment() {
        let responsesDataController = DiscussionResponsesDataController()
        
        let endorsedResponses = DiscussionTestsDataFactory.endorsedResponses()
        let unendorsedResponses = DiscussionTestsDataFactory.unendorsedResponses()
        
        responsesDataController.endorsedResponses = endorsedResponses
        responsesDataController.responses = unendorsedResponses
        
        // Test adding child comment in unendorsed response
        let unendorsedComment = unendorsedResponses[1]
        responsesDataController.addedChildComment(unendorsedComment)
        let updatedComment = responsesDataController.responses[1]
        
        XCTAssertEqual(unendorsedComment.childCount + 1, updatedComment.childCount)
        XCTAssertNotEqual(unendorsedComment.childCount + 1, responsesDataController.responses[0].childCount)
        
        // Test adding child comment in endorsed response
        let endorsedComment = endorsedResponses[0]
        responsesDataController.addedChildComment(endorsedComment)
        let updatedEndorsedComment = responsesDataController.endorsedResponses[0]
        
        XCTAssertEqual(endorsedComment.childCount + 1, updatedEndorsedComment.childCount)
        XCTAssertNotEqual(endorsedComment.childCount + 1, responsesDataController.endorsedResponses[1].childCount)
    }
    
}