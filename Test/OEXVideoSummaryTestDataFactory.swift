//
//  OEXVideoSummaryTestDataFactory.swift
//  edX
//
//  Created by Akiva Leffert on 5/11/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

// This is temporarily part of the edX target instead of the edXTests target so we can use it as a fixture
// during development. When that is not being done any more we should hook it up to the test target only

class OEXVideoSummaryTestDataFactory {
    
    /// A video that can be accessed from the file system
    static func localVideoWithID(_ videoID: String, pathIDs: [String], encodings: [AnyHashable:Any]? = nil) -> OEXVideoSummary {
        var videoPath: String = Bundle(for: self).path(forResource: "test-movie", ofType: ".mp4")!
        videoPath = videoPath.replacingOccurrences(of: ".mp4", with: "")
        let info : [AnyHashable: Any] = [
            "section_url": "url://to/nowhere",
            "path": [
                [
                    "category": "chapter",
                    "name": "Introduction",
                    "id": pathIDs[0]
                ],
                [
                    "category": "sequential",
                    "name": "Welcome to an edX Course!",
                    "id": pathIDs[1]
                ],
                [
                    "category": "vertical",
                    "name": "Navigating an edX Course",
                    "id": pathIDs[2]
                ]
            ],
            "unit_url": "url://to/nowhere",
            "summary": [
                "category": "video",
                "video_url": videoPath,
                "language": "en",
                "name": "Navigating an edX Course",
                "only_on_web": false,
                "id": videoID,
                "size": 0,
                "duration" : 100,
                "encoded_videos": encodings ?? [:],
                "transcripts": ["en": TranscriptDataFactory.validTranscriptString]
            ]
        ]
        return OEXVideoSummary(dictionary: info)
    }
    
    // This method create the mock video objects
    static func localCourseVideos(_ videoID : String) -> [OEXHelperVideoDownload]{
        
        let video1 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot1", "section1dot1"], encodings:["mobile_low":["file_size":3700000, "url":"https://www.example.com/video.mp4"]])
        let video2 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot1", "section1dot1"], encodings:["mobile_low":["file_size":3700000, "url":"https://www.example.com/video.mp4"]])
        let video3 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot2", "section1dot1"], encodings:["mobile_low":["file_size":3700000, "url":"https://www.example.com/video.mp4"]])
        let video4 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section2dot1", "section1dot1"], encodings:["mobile_low":["file_size":3700000, "url":"https://www.example.com/video.mp4"]])
        
        let video5 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section2dot1", "section1dot1"], encodings:["mobile_low":["file_size":3700000, "url":"https://www.example.com/video.mp4"], "mobile_high":["file_size":3700000, "url":"https://www.example.com/video.mp4"]])
        
        return OEXVideoSummaryTestDataFactory.videos(with: [video1, video2, video3, video4, video5])
    }
    
    static func localCourseVideoWithoutEncodings(_ videoID: String) -> [OEXHelperVideoDownload]{
        
        let video1 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot1", "section1dot1"])
        let video2 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot1", "section1dot1"])
        let video3 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section2dot1", "section1dot1"])
        
        return OEXVideoSummaryTestDataFactory.videos(with: [video1, video2, video3])
    }
    
    private static func videos(with summaries:[OEXVideoSummary]) ->[OEXHelperVideoDownload] {
        var videosArray: [OEXHelperVideoDownload] = []
        for videoSummary in summaries {
            let helperVideoDownload = OEXHelperVideoDownload()
            helperVideoDownload.summary = videoSummary
            helperVideoDownload.filePath = videoSummary.videoURL ?? ""
            videosArray.append(helperVideoDownload)
        }
        
        return videosArray
    }
}
