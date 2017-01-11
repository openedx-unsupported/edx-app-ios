//
//  VideoBlockViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 3/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

@testable import edX

class VideoBlockViewControllerTests : SnapshotTestCase {

    func testSnapshotYoutubeOnly() {
        // Create a course with a youtube video
        let summary = OEXVideoSummary(videoID: "some-video", name: "Youtube Video", encodings: [
            OEXVideoEncodingYoutube: OEXVideoEncoding(name: OEXVideoEncodingYoutube, URL: "https://some-youtube-url", size: 12)])
        let outline = CourseOutline(root: "root", blocks: [
            "root" : CourseBlock(type: CourseBlockType.Course, children: ["video"], blockID: "root", minifiedBlockID: "123456", name: "Root", multiDevice: true, graded: false),
            "video" : CourseBlock(type: CourseBlockType.Video(summary), children: [], blockID: "video", minifiedBlockID: "123456", name: "Youtube Video", blockURL: NSURL(string: "www.example.com"), multiDevice: true, graded: false)
            ])

        let environment = TestRouterEnvironment()
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: "some-course", outline: outline)

        let videoController = VideoBlockViewController(environment: environment, blockID: "video", courseID: "some-course")
        inScreenNavigationContext(videoController) {
            assertSnapshotValidWithContent(videoController.navigationController!)
        }
    }
}
