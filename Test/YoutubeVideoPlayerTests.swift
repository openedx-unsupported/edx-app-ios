//
//  YoutubeVideoPlayerTests.swift
//  edXTests
//
//  Created by AndreyCanon on 9/28/18.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest
@testable import edX

class YoutubeVideoPlayerTests: XCTestCase {
    
    let course = OEXCourse.freshCourse()
    var outline: CourseOutline!
    var environment: TestRouterEnvironment!
    var youtubeVideoPlayer : YoutubeVideoPlayer?
    let networkManager = MockNetworkManager(baseURL: URL(string: "www.example.com")!)
    
    override func setUp() {
        super.setUp()
        outline = CourseOutlineTestDataFactory.freshCourseOutline(course.course_id!)
        let youtubeConfig = ["ENABLED": false, "YOUTUBE_API_KEY": "test12345"] as [String: Any]
        let config = OEXConfig(dictionary: ["COURSE_VIDEOS_ENABLED": true, "YOUTUBE_VIDEO": youtubeConfig])
        let interface = OEXInterface.shared()
        environment = TestRouterEnvironment(config: config, interface: interface)
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: outline.root, interface: interface, outline: outline)
        youtubeVideoPlayer = YoutubeVideoPlayer(environment: environment)
    }
    
    func testVideoPlay() {
        let summary = OEXVideoSummary(videoID: "some-video", name: "Youtube Video", encodings: [
            OEXVideoEncodingYoutube: OEXVideoEncoding(name: OEXVideoEncodingYoutube, url: "https://some-youtube-url/watch?v=abc123", size: 12)])
        let video = OEXHelperVideoDownload()
        video.summary = summary
        youtubeVideoPlayer?.play(video: video)
        XCTAssertEqual("abc123", youtubeVideoPlayer?.videoId)
    }
    
    func testVideoPlayerProtraitView() {
        let screenSize: CGRect = UIScreen.main.bounds
        youtubeVideoPlayer?.videoPlayerProtraitView(portraitView: false)
        var landScapeSize = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        
        XCTAssertEqual(landScapeSize, youtubeVideoPlayer?.playerView.frame)
        
        landScapeSize = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.width * 9 / 16)
        
        youtubeVideoPlayer?.videoPlayerProtraitView(portraitView: true)
        
        XCTAssertEqual(landScapeSize, youtubeVideoPlayer?.playerView.frame)
    }
    
    func testViewDidLoad() {
        youtubeVideoPlayer?.viewDidLoad()
        XCTAssertTrue((youtubeVideoPlayer?.playerView.isDescendant(of: (youtubeVideoPlayer?.view)!))!)        
    }
}
