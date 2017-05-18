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
        responsesDataController.addedChildComment(comment: unendorsedComment)
        let updatedComment = responsesDataController.responses[1]
        
        XCTAssertEqual(unendorsedComment.childCount + 1, updatedComment.childCount)
        XCTAssertNotEqual(unendorsedComment.childCount + 1, responsesDataController.responses[0].childCount)
        
        // Test adding child comment in endorsed response
        let endorsedComment = endorsedResponses[0]
        responsesDataController.addedChildComment(comment: endorsedComment)
        let updatedEndorsedComment = responsesDataController.endorsedResponses[0]
        
        XCTAssertEqual(endorsedComment.childCount + 1, updatedEndorsedComment.childCount)
        XCTAssertNotEqual(endorsedComment.childCount + 1, responsesDataController.endorsedResponses[1].childCount)
    }
    
    func testResponseVoting() {
        let responses = DiscussionTestsDataFactory.endorsedResponses()
        let responsesDataController = DiscussionResponsesDataController()
        responsesDataController.endorsedResponses = responses
        
        // Test response vote increment
        var testResponse = responses[0]
        testResponse.voteCount += 1
        testResponse.voted = !testResponse.voted
        
        responsesDataController.updateResponsesWithComment(comment: testResponse)
        
        XCTAssertEqual(responses[0].voteCount + 1, responsesDataController.endorsedResponses[0].voteCount)
        XCTAssertEqual(!responses[0].voted, responsesDataController.endorsedResponses[0].voted)
        XCTAssertTrue(responsesDataController.endorsedResponses[0].voted)
        
        // Test response vote decrement
        var votedResponse = responsesDataController.endorsedResponses[0]
        votedResponse.voteCount -= 1
        votedResponse.voted = !votedResponse.voted
        
        responsesDataController.updateResponsesWithComment(comment: votedResponse)
        
        XCTAssertEqual(responses[0].voteCount, responsesDataController.endorsedResponses[0].voteCount)
        XCTAssertEqual(responses[0].voted, responsesDataController.endorsedResponses[0].voted)
        XCTAssertFalse(responsesDataController.endorsedResponses[0].voted)
        
    }
    
    func testResponseAbuseFlagging() {
        
        let responses = DiscussionTestsDataFactory.endorsedResponses()
        let responsesDataController = DiscussionResponsesDataController()
        responsesDataController.endorsedResponses = responses
        
        // Test response mark abuse
        var testResponse = responses[0]
        testResponse.abuseFlagged = !testResponse.abuseFlagged
        
        responsesDataController.updateResponsesWithComment(comment: testResponse)
        
        XCTAssertEqual(!responses[0].abuseFlagged, responsesDataController.endorsedResponses[0].abuseFlagged)
        XCTAssertTrue(responsesDataController.endorsedResponses[0].abuseFlagged)
        
        // Test response unabused
        var flaggedResponse = responsesDataController.endorsedResponses[0]
        flaggedResponse.abuseFlagged = !flaggedResponse.abuseFlagged
        
        responsesDataController.updateResponsesWithComment(comment: flaggedResponse)
    
        XCTAssertEqual(responses[0].abuseFlagged, responsesDataController.endorsedResponses[0].abuseFlagged)
        XCTAssertFalse(responsesDataController.endorsedResponses[0].abuseFlagged)
    }
    
}
