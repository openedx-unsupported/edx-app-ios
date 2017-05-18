//
//  VideoTranscriptTests.swift
//  edX
//
//  Created by Danial Zahid on 1/11/17.
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
        
        transcriptView.updateTranscript(transcript: VideoTranscriptDataFactory.transcriptArray())
        
        XCTAssertEqual(transcriptView.transcriptTableView.numberOfRows(inSection: 0), 5)
        XCTAssertFalse(transcriptView.transcriptTableView.isHidden)
    }
    
    func testTranscriptSeek() {
        let environment = TestRouterEnvironment()
        let transcriptView = VideoTranscript(environment: environment)
        transcriptView.updateTranscript(transcript: VideoTranscriptDataFactory.transcriptArray())
        
        transcriptView.highlightSubtitleForTime(time: 1.75)
        XCTAssertEqual(transcriptView.highlightedIndex, 1)
        
        transcriptView.highlightSubtitleForTime(time: 3.45)
        XCTAssertEqual(transcriptView.highlightedIndex, 2)
        
        transcriptView.highlightSubtitleForTime(time: 3.47)
        XCTAssertEqual(transcriptView.highlightedIndex, 2)
    }
}

class VideoTranscriptDataFactory{
    
    static func transcriptArray() -> [AnyObject] {
        var transcript = [[String: AnyObject]]()
        
        transcript.append(["kIndex":0 as AnyObject,
            "kStart":0.0 as AnyObject,
            "kText":">> Test transcript text" as AnyObject,
            "kEnd":1.45 as AnyObject])
        
        transcript.append(["kIndex":1 as AnyObject,
            "kStart":1.46 as AnyObject,
            "kText":"Test transcript text" as AnyObject,
            "kEnd":2.45 as AnyObject])
        
        transcript.append(["kIndex":2 as AnyObject,
            "kStart":2.46 as AnyObject,
            "kText":"Test transcript text" as AnyObject,
            "kEnd":3.45 as AnyObject])
        
        transcript.append(["kIndex":3 as AnyObject,
            "kStart":3.50 as AnyObject,
            "kText":"Test transcript text" as AnyObject,
            "kEnd":4.45 as AnyObject])
        
        transcript.append(["kIndex":4 as AnyObject,
            "kStart":4.46 as AnyObject,
            "kText":"Test transcript text" as AnyObject,
            "kEnd":5.45 as AnyObject])

        return transcript as [AnyObject]
    }
}
