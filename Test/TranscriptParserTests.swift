//
//  TranscriptParserTests.swift
//  edX
//
//  Created by Salman on 13/03/2018.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class TranscriptParserTests: XCTestCase {
    
    func testValidCaptions() {
        
        let expectation = self.expectation(description: "Parsing Transcript")
    
        let transcriptParser = TranscriptParser()
        transcriptParser.parse(transcript: TranscriptDataFactory.validTranscriptString) { (success, error) in
            XCTAssertTrue(success)
            XCTAssertEqual(transcriptParser.transcripts.count, 11)
            expectation.fulfill()
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
        
        waitForExpectations { (error) in
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
    }
    
    func testPartialCaptions() {
        let expectation = self.expectation(description: "Parsing Transcript")
        let transcriptParser = TranscriptParser()
        transcriptParser.parse(transcript: TranscriptDataFactory.partialTranscriptString) { (success, error) in
            XCTAssertTrue(success)
            XCTAssertEqual(transcriptParser.transcripts.count, 10)
            expectation.fulfill()
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
    
        waitForExpectations { (error) in
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
    }
    
    func testInvalidCaptions() {
        let expectation = self.expectation(description: "Parsing Transcript")
        let transcriptParser = TranscriptParser()
        transcriptParser.parse(transcript: TranscriptDataFactory.invalidTranscriptString) { (success, error) in
            XCTAssertFalse(success)
            expectation.fulfill()
            if error != nil {
                XCTAssertEqual(error?.localizedDescription, "Invalid Format")
            }
        }
        
        waitForExpectations { (error) in
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
    }
    
    func testEmptyCaptions() {
        let expectation = self.expectation(description: "Parsing Transcript")
        let transcriptParser = TranscriptParser()
        transcriptParser.parse(transcript: TranscriptDataFactory.emptyTranscriptString) { (success, error) in
            XCTAssertFalse(success)
            XCTAssertEqual(transcriptParser.transcripts.count, 0)
            expectation.fulfill()
            if error != nil {
                XCTAssertEqual(error?.localizedDescription, "Invalid Format")
            }
        }
        
        waitForExpectations { (error) in
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
    }
    
    func testMissingSecondsCaptions() {
        
        let expectation = self.expectation(description: "Parsing Transcript")
        
        let transcriptParser = TranscriptParser()
        transcriptParser.parse(transcript: TranscriptDataFactory.missingSecondsInTranscriptString) { (success, error) in
            XCTAssertTrue(success)
            XCTAssertEqual(transcriptParser.transcripts.count, 3)
            expectation.fulfill()
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
        
        waitForExpectations { (error) in
            if error != nil {
                XCTFail("Transcript parsing failed")
            }
        }
    }
    
}

class TranscriptDataFactory {
    
    static let validTranscriptString = "0\n00:00:00,360 --> 00:00:04,790\nThis is the first test text.\n\n1\n00:00:04,790 --> 00:00:09,090\nThis is the second test text.\n\n2\n00:00:09,090 --> 00:00:11,910\nThis is the third test text.\n\n3\n00:00:12,930 --> 00:00:16,800\nThis is the fourth test text.\n\n4\n00:00:16,800 --> 00:00:18,760\nThis is the fifth test text.\n\n5\n00:00:18,760 --> 00:00:21,040\nThis is the sixth test text.\n\n6\n00:00:21,040 --> 00:00:22,880\nThis is the seventh test text.\n\n7\n00:00:22,880 --> 00:00:26,410\nThis is the eight test text.\n\n8\n00:00:26,410 --> 00:00:28,150\nThis is the ninth test text.\n\n9\n00:00:28,150 --> 00:00:31,360\nThis is the tenth test text.\n\n10\n00:00:31,360 --> 00:00:35,310\nThis is the eleventh test text.\n"
    
    static let partialTranscriptString = "0\n00:00:00,360 --> 00:00:04,790\nThis is the first test text.\n\n1\n00:00:04,790 --> 00:00:09,090\n\n\n2\n00:00:09,090 --> 00:00:11,910\nThis is the third test text.\n\n3\n00:00:12,930 --> 00:00:16,800\nThis is the fourth test text.\n\n4\n00:00:16,800 --> 00:00:18,760\nThis is the fifth test text.\n\n5\n00:00:18,760 --> 00:00:21,040\nThis is the sixth test text.\n\n6\n00:00:21,040 --> 00:00:22,880\nThis is the seventh test text.\n\n7\n00:00:22,880 --> 00:00:26,410\nThis is the eight test text.\n\n8\n00:00:26,410 --> 00:00:28,150\nThis is the ninth test text.\n\n9\n00:00:28,150 --> 00:00:31,360\nThis is the tenth test text.\n\n10\n00:00:31,360 --> 00:00:35,310\nThis is the eleventh test text.\n"
    
    static let missingSecondsInTranscriptString = "0\n00:00:00 --> 00:00\nThis is the first test text.\n\n1\n00:00: --> 00:00:09,090\nThis is the second test text.\n\n2\n00:00:09,090 --> 00:00:11,910\nThis is the third test text.\n"
    
    static let invalidTranscriptString = "{\"developer_message\":\"The provided access token does not match any valid tokens.\",\"error_code\":\"token_nonexistent\"}"
    
    static let emptyTranscriptString = ""

}
