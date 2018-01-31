//
//  DashboardVideoTabHeaderViewTests.swift
//  edXTests
//
//  Created by Muhammad Zeeshan Arif on 31/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

@testable import edX
import Foundation

class DashboardVideoTabHeaderViewTests : SnapshotTestCase {
    
    func testCourseVideosHeaderView() {
        let course = OEXCourse.accessibleTestCourse()
        let interface = OEXInterface.shared()
        interface.t_setCourseVideos([course.video_outline!: OEXVideoSummaryTestDataFactory.localCourseVideos(CourseOutlineTestDataFactory.knownLocalVideoID)])
        let courseVideosHeaderView = CourseVideosHeaderView(with: course, interface: interface)
        courseVideosHeaderView.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: CourseVideosHeaderView.height)
        courseVideosHeaderView.refreshView()
        courseVideosHeaderView.layoutIfNeeded()
        assertSnapshotValidWithContent(courseVideosHeaderView)
    }
}
