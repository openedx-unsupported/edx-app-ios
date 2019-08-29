//
//  YoutubeVideoConfigTests.swift
//  edXTests
//
//  Created by Andrey Canon on 4/12/19.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

@testable import edX

class YoutubeVideoConfigTests: XCTestCase {
    
    func testNoYoutubeVideoConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.youtubeVideoConfig.enabled)
    }
    
    func testEmptyYoutubeVideoConfig() {
        let config = OEXConfig(dictionary:["YOUTUBE_VIDEO":[:]])
        XCTAssertFalse(config.youtubeVideoConfig.enabled)
    }
    
    func testYoutubeVideoConfig() {
        let configDictionary = [
            "YOUTUBE_VIDEO" : [
                "ENABLED": true,
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.youtubeVideoConfig.enabled)
    }
    
    func testYoutubeVideoDisableConfig() {
        let configDictionary = [
            "YOUTUBE_VIDEO" : [
                "ENABLED": false,
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.youtubeVideoConfig.enabled)

    }
}
