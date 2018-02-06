//
//  CourseOutlineHeaderViewTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

@testable import edX
import Foundation

class CourseOutlineHeaderViewTests : SnapshotTestCase {
    
    func testHeaderInfoView() {
        let headerInfoView = CourseOutlineHeaderView(frame: CGRect.zero, styles: OEXStyles(), titleText: Strings.lastAccessed, subtitleText : "This is a very long subtitle which should not overlap the button")
        
        let size = headerInfoView.systemLayoutSizeFitting(self.screenSize)
        // Using 380 to make sure that the subtitle truncates
        headerInfoView.bounds = CGRect(x: 0, y: 0, width: 380, height: size.height)
        
        headerInfoView.layoutIfNeeded()
        assertSnapshotValidWithContent(headerInfoView)
    }
    
    func testCourseVideosHeaderView() {
        let course = OEXCourse.accessibleTestCourse()
        let interface = OEXInterface.shared()
        interface.t_setCourseVideos([course.video_outline!: OEXVideoSummaryTestDataFactory.localCourseVideos(CourseOutlineTestDataFactory.knownLocalVideoID)])
        let mockEnv = TestRouterEnvironment(config: OEXConfig(dictionary: [:]), interface: interface)
        let courseVideosHeaderView = CourseVideosHeaderView(with: course, environment: mockEnv)
        courseVideosHeaderView.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: CourseVideosHeaderView.height)
        courseVideosHeaderView.refreshView()
        courseVideosHeaderView.layoutIfNeeded()
        assertSnapshotValidWithContent(courseVideosHeaderView)
    }
    
}
