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
    var outline: CourseOutline!
    var environment: TestRouterEnvironment!
    var videoPlayer : VideoPlayer?
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

    func loadVideoPlayer(_ completion: ( (_ videoPlayer : VideoPlayer) -> Void)? = nil) {
            videoPlayer = VideoPlayer(environment: environment)
            videoPlayer?.view.layoutIfNeeded()
            if let video = environment.interface?.stateForVideo(withID: CourseOutlineTestDataFactory.knownLocalVideoID, courseID: course.course_id!) {
                    self.videoPlayer?.play(video: video)
            }
            let expectations = expectation(description: "player ready to play")
            let removable = addNotificationObserver(observer: self, name: "TestPlayerStatusDidChangedToReadyState") { [weak self] _ in
                if let videoPlayer = self?.videoPlayer {
                    completion?(videoPlayer)
                }
                expectations.fulfill()
            }
            waitForExpectations()
            removable.remove()
            stopPlayer()
    }
    
    func stopPlayer() {
        videoPlayer?.t_stop()
    }
    
    // Test the video is playing successfully.
    // Video player has three states unknown, readyToPlay, failed.
    // For successful play the state should be readyToPlay
    func testVideoPlay() {
        loadVideoPlayer { videoPlayer in
            XCTAssertEqual(videoPlayer.t_playerCurrentState, .readyToPlay)
            XCTAssertGreaterThan(videoPlayer.rate, 0)
        }
    }
    
    // Test the video is paused successfully
    // We have to check the rate of player for the video paused state
    // if the rate is zero, mean the video is currently not playing.
    func testVideoPause() {
        loadVideoPlayer { videoPlayer in
            XCTAssertEqual(videoPlayer.t_playerCurrentState, .readyToPlay)
            XCTAssertGreaterThan(videoPlayer.rate, 0)
            videoPlayer.t_pause()
            XCTAssertEqual(videoPlayer.rate, 0)
        }
    }
    
    // Test the video is resume successfully
    func testVideoResume() {
        loadVideoPlayer { videoPlayer in
            XCTAssertEqual(videoPlayer.t_playerCurrentState, .readyToPlay)
            videoPlayer.seek(to: 10.168155555555558)
            videoPlayer.t_controls?.durationSliderValue = 1.01
            let  pauseTime = videoPlayer.currentTime
            XCTAssertGreaterThan(videoPlayer.rate, 0)
            videoPlayer.t_pause()
            XCTAssertEqual(videoPlayer.rate, 0)
            videoPlayer.t_resume()
            let resumeTime = videoPlayer.currentTime
            XCTAssertGreaterThanOrEqual(resumeTime, pauseTime)
        }
    }
    
    // Test the backwarward seek functionality
    func testSeekBackword() {
        loadVideoPlayer { videoPlayer in
            XCTAssertEqual(videoPlayer.t_playerCurrentState, .readyToPlay)
            videoPlayer.seek(to: 34.168155555555558)
            videoPlayer.t_controls?.durationSliderValue = 1.01
            videoPlayer.seekBackwardPressed(playerControls: videoPlayer.t_controls!)
            let currentTime = videoPlayer.currentTime
            XCTAssertGreaterThanOrEqual(currentTime, 3.93)
        }
    }
    
    // Test the seeking functionality 
    func testSeeking() {
        loadVideoPlayer { videoPlayer in
            XCTAssertEqual(videoPlayer.t_playerCurrentState, .readyToPlay)
            videoPlayer.seek(to: 34.168155555555558)
            videoPlayer.t_controls?.durationSliderValue = 1.01
            let currentTime = videoPlayer.currentTime
            XCTAssertGreaterThanOrEqual(currentTime, 33.934)
            XCTAssertGreaterThan(videoPlayer.rate, 0)
        }
    }
    
    // Test for video speed setting
    func testVideoSpeedSetting() {
        loadVideoPlayer { videoPlayer in
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
    }
    
    // Test the activation and deactivation of subtitles
    func testSubtitleActivation() {
        loadVideoPlayer { videoPlayer in
            //Subtitle will be deactivated by defaule
            XCTAssertFalse(videoPlayer.t_subtitleActivated)
            videoPlayer.t_controls?.activateSubTitles()
            XCTAssertTrue(videoPlayer.t_subtitleActivated)
            videoPlayer.t_controls?.deAvtivateSubTitles()
            XCTAssertFalse(videoPlayer.t_subtitleActivated)
        }
    }
    
    // Test the subtitle language setting
    func testSubtitleLanguage() {
        loadVideoPlayer { videoPlayer in
            let defaultSelectedLanguage = OEXInterface.getCCSelectedLanguage() ?? "abc"
            // check that no language selected
            XCTAssertEqual(defaultSelectedLanguage, "")
            videoPlayer.t_captionLanguage = "en"
            XCTAssertEqual(videoPlayer.t_captionLanguage, "en")
            videoPlayer.t_captionLanguage = "es"
            XCTAssertEqual(videoPlayer.t_captionLanguage, "es")
            videoPlayer.t_captionLanguage = defaultSelectedLanguage
        }
    }
}
