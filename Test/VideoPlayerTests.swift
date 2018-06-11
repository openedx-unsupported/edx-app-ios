//
//  VideoPlayerTests.swift
//  edXTests
//
//  Created by Salman on 07/06/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest
@testable import edX

class VideoPlayerTests: XCTestCase {
    
    let course = OEXCourse.freshCourse()
    var outline : CourseOutline!
    var environment : TestRouterEnvironment!
    var videoPlayer : VideoPlayer!
    let networkManager = MockNetworkManager(baseURL: URL(string: "www.example.com")!)
    
    override func setUp() {
        super.setUp()
        outline = CourseOutlineTestDataFactory.freshCourseOutline(course.course_id!)
        let config = OEXConfig(dictionary: ["COURSE_VIDEOS_ENABLED": true, "TAB_LAYOUTS_ENABLED": true])
        let interface = OEXInterface.shared()
        environment = TestRouterEnvironment(config: config, interface: interface)
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: outline.root, interface: interface, outline: outline)
        environment.interface?.t_setCourseEnrollments([UserCourseEnrollment(course: course)])
        environment.interface?.t_setCourseVideos([course.video_outline!: OEXVideoSummaryTestDataFactory.localCourseVideoWithoutEncodings(CourseOutlineTestDataFactory.knownLocalVideoID)])
    }
    
    func loadVideoPlayer() {
        videoPlayer = VideoPlayer(environment: environment)
        videoPlayer.view.layoutIfNeeded()
        if let video = environment.interface?.stateForVideo(withID: CourseOutlineTestDataFactory.knownLocalVideoID, courseID: course.course_id!) {
            videoPlayer.play(video: video)
        }
    }
    
    // Test the video is playing successfully.
    // Video player has three states unknown, readyToPlay, failed.
    // For successful play the state should be readyToPlay
    func testVideoPlay() {
        let expectations = expectation(description: "player ready to play")
        loadVideoPlayer()
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyState") { (_, _, removable) -> Void in
            expectations.fulfill()
        }
        waitForExpectations()
        removable.remove()
        XCTAssertEqual(videoPlayer.t_playerCurrentState, .readyToPlay)
    }
    
    // Test the video is paused successfully
    // We have to check the rate of player for the video paused state
    // if the rate is zero, mean the video is currently not playing.
    func testVideoPause() {
        loadVideoPlayer()
        let expectations = expectation(description: "player ready to play")
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyState") { (_, _, removable) -> Void in
            expectations.fulfill()
        }
        waitForExpectations()
        removable.remove()
        videoPlayer.playPausePressed(playerControls: videoPlayer.t_controls!, isPlaying: false)
        XCTAssertEqual(videoPlayer.rate, 0)
    }
    
    // Test the video resume functionality at specific time interval
    func testResumeTime() {
        let expectations = expectation(description: "player ready to play")
        loadVideoPlayer()
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyState") { [weak self] (_, _, removable) -> Void  in
            expectations.fulfill()
            self?.videoPlayer.resume(at: 2.0)
        }
        waitForExpectations()
        removable.remove()
        XCTAssertGreaterThanOrEqual(videoPlayer.currentTime, 2.0)
    }
    
    // Test the backwarward seek functionality
    func testSeekBackword() {
        let expectations = expectation(description: "player ready to play")
        loadVideoPlayer()
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyState") { (_, _, removable) -> Void in
            expectations.fulfill()
        }
        waitForExpectations()
        removable.remove()
        videoPlayer.seekBackwardPressed(playerControls: videoPlayer.t_controls!)
        let currentTime = videoPlayer.currentTime
        
        // The test video size is 34sec and the video backward skip duration is 30sec
        // we have to give margin of at least 3-4 seconds as if we seek the video
        // backward or forward at specific time the player actually start to run
        // maximum or minimum 3-4 seconds before or after.
        XCTAssertGreaterThanOrEqual(currentTime, 0.066712999999999995)
    }
    
    // Test for video speed setting
    func testVideoSpeedSetting() {
        let expectations = expectation(description: "player ready to play")
        loadVideoPlayer()
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyState") { (_, _, removable) -> Void in
            expectations.fulfill()
        }
        waitForExpectations()
        removable.remove()
        let defaultPlaybackSpeed = OEXInterface.getCCSelectedPlaybackSpeed()
        XCTAssertEqual(videoPlayer.t_playBackSpeed, defaultPlaybackSpeed)
        videoPlayer.t_playBackSpeed = .fast
        XCTAssertEqual(videoPlayer.t_playBackSpeed, .fast)
        videoPlayer.t_playBackSpeed = .slow
        XCTAssertEqual(videoPlayer.t_playBackSpeed, .slow)
        videoPlayer.t_playBackSpeed = .xFast
        XCTAssertEqual(videoPlayer.t_playBackSpeed, .xFast)
        videoPlayer.t_playBackSpeed = defaultPlaybackSpeed
    }
    
    func testSeeking() {
        let expectations = expectation(description: "player ready to play")
        loadVideoPlayer()
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyState") { (_, _, removable) -> Void in
            expectations.fulfill()
        }
        waitForExpectations()
        removable.remove()
        videoPlayer.seek(to: 5.0)
        
        // we have to give margin of at least 3-4 seconds as if we seek the video
        // backward or forward at specific time the player actually start to run
        // maximum or minimum 3-4 seconds before or after.
        XCTAssertGreaterThanOrEqual(videoPlayer.currentTime, 5.0)
        XCTAssertLessThan(videoPlayer.currentTime, 8.0)
    }
    
    // Test the activation and deactivation of subtitles
    func testSubtitleActivation() {
        let expectations = expectation(description: "player ready to play")
        loadVideoPlayer()
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyState") { (_, _, removable) -> Void in
            expectations.fulfill()
        }
        waitForExpectations()
        removable.remove()
        videoPlayer.t_controls?.activateSubTitles()
        XCTAssertTrue(videoPlayer.t_subtitleActivated)
        videoPlayer.t_controls?.deAvtivateSubTitles()
        XCTAssertFalse(videoPlayer.t_subtitleActivated)
    }
    
    // Test the subtitle language setting
    func testSubtitleLanguage() {
        let expectations = expectation(description: "player ready to play")
        loadVideoPlayer()
        let removable = addNotificationObserver(observer: self, name: "TestNotificationForPlayerReadyStateVideoPlayer.swift") { (_, _, removable) -> Void in
            expectations.fulfill()
        }
        waitForExpectations()
        removable.remove()
        let currentSelectedLanguage = OEXInterface.getCCSelectedLanguage() ?? "en"
        videoPlayer.t_captionLanguage = "en"
        XCTAssertEqual(videoPlayer.t_captionLanguage, "en")
        videoPlayer.t_captionLanguage = "es"
        XCTAssertEqual(videoPlayer.t_captionLanguage, "es")
        videoPlayer.t_captionLanguage = currentSelectedLanguage
    }
}
