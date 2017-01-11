//
//  OEXVideoTranscriptTests.swift
//  edX
//
//  Created by Danial Zahid on 1/11/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class OEXVideoTranscriptTests: XCTestCase {
    
    func testTranscriptLoaded() {
        let transcriptView = OEXVideoTranscript()
        
        XCTAssertEqual(transcriptView.transcriptTableView.numberOfRowsInSection(0), 0)
        XCTAssertTrue(transcriptView.transcriptTableView.hidden)
        
        transcriptView.updateTranscript(OEXVideoTranscriptDataFactory.transcriptArray())
        
        XCTAssertEqual(transcriptView.transcriptTableView.numberOfRowsInSection(0), 5)
        XCTAssertFalse(transcriptView.transcriptTableView.hidden)
    }
    
    func testTransctipSeek() {
        let transcriptView = OEXVideoTranscript()
        transcriptView.updateTranscript(OEXVideoTranscriptDataFactory.transcriptArray())
        
        transcriptView.highlightSubtitleForTime(1.75)
        XCTAssertEqual(transcriptView.selectedIndex, 1)
        
        transcriptView.highlightSubtitleForTime(3.45)
        XCTAssertEqual(transcriptView.selectedIndex, 2)
        
        transcriptView.highlightSubtitleForTime(3.47)
        XCTAssertEqual(transcriptView.selectedIndex, 2)
    }
    
}

class OEXVideoTranscriptDataFactory{
    
    static func transcriptArray() -> [AnyObject] {
        var transcript = [[String: AnyObject]]()
        
        transcript.append(["kIndex":0,
                           "kStart":0.0,
                           "kText":">> Test transcript text",
                           "kEnd":1.45])
        
        transcript.append(["kIndex":1,
                           "kStart":1.46,
                           "kText":"Test transcript text",
                           "kEnd":2.45])
        
        transcript.append(["kIndex":2,
                           "kStart":2.46,
                           "kText":"Test transcript text",
                           "kEnd":3.45])
        
        transcript.append(["kIndex":3,
                           "kStart":3.50,
                           "kText":"Test transcript text",
                           "kEnd":4.45])
        
        transcript.append(["kIndex":4,
                           "kStart":4.46,
                           "kText":"Test transcript text",
                           "kEnd":5.45])
        
        return transcript
    }
    
}
