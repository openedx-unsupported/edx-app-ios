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
                "duration" : 100
            ]
        ]
        return OEXVideoSummary(dictionary: info)
    }
}
