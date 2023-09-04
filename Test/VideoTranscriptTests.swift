//
//  VideoTranscriptTests.swift
//  edX
//
//  Created by Danial Zahid on 1/11/17.
//  Updated by Salman on 05/03/2018.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class VideoTranscriptTests: XCTestCase {
    
    func testTranscriptLoaded() {
        let environment = TestRouterEnvironment()
        let transcriptView = VideoTranscript(environment: environment)
        
        XCTAssertEqual(transcriptView.transcriptTableView.numberOfRows(inSection: 0), 0)
        XCTAssertTrue(transcriptView.transcriptTableView.isHidden)
        
        let transcriptParser = TranscriptParser()
        transcriptParser.parse(transcript: TranscriptDataFactory.validTranscriptString) { (success, error) in
            if success {
                transcriptView.updateTranscript(transcript: transcriptParser.transcripts)
            }
        }
        
        XCTAssertEqual(transcriptView.transcriptTableView.numberOfRows(inSection: 0), 11)
        XCTAssertFalse(transcriptView.transcriptTableView.isHidden)
    }
    
    func testTranscriptSeek() {
        let environment = TestRouterEnvironment()
        let transcriptView = VideoTranscript(environment: environment)
        
        let transcriptParser = TranscriptParser()
        transcriptParser.parse(transcript: TranscriptDataFactory.validTranscriptString) { (success, error) in
            if success {
                transcriptView.updateTranscript(transcript: transcriptParser.transcripts)
            }
        }

        transcriptView.highlightSubtitle(for: 4.83)
        XCTAssertEqual(transcriptView.highlightedIndex, 1)

        transcriptView.highlightSubtitle(for: 10.0)
        XCTAssertEqual(transcriptView.highlightedIndex, 2)

        transcriptView.highlightSubtitle(for: 12.93)
        XCTAssertEqual(transcriptView.highlightedIndex, 3)
    }
}
