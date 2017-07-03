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
    static func localVideoWithID(_ videoID : String, pathIDs: [String]) -> OEXVideoSummary {
        let videoPath : String = Bundle(for: self).url(forResource: "test-movie", withExtension: "m4v")!.absoluteString
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
                "encoded_videos":[
                "mobile_low":[
                    "file_size":0,
                    "url":"https://www.example.com/video.mp4"
                    ]
                ]
            ]
        ]
        return OEXVideoSummary(dictionary: info)
    }
    
    // This method create the mock video objects
    static func localCourseVideos(_ videoID : String) -> [OEXHelperVideoDownload]{

        let video1 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot1", "section1dot1"])
        let video2 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot1", "section1dot1"])
        let video3 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section1dot2", "section1dot1"])
        let video4 = OEXVideoSummaryTestDataFactory.localVideoWithID(videoID, pathIDs: ["chapterid1", "section2dot1", "section1dot1"])
        
        let videoSummaries = [video1, video2, video3, video4]
        var videosArray : [OEXHelperVideoDownload] = []
        var helperVideoDownload : OEXHelperVideoDownload
        for videoSummary in videoSummaries {
            helperVideoDownload = OEXHelperVideoDownload()
            helperVideoDownload.summary = videoSummary
            videosArray.append(helperVideoDownload)
        }
        
        return videosArray
    }
}

