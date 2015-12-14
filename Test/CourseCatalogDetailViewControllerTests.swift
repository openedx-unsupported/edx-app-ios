//
//  CourseCatalogDetailViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX

class CourseCatalogDetailViewControllerTests: SnapshotTestCase {
    func testSnapshotAboutScreen() {
        let environment = TestRouterEnvironment()
        let endDate = NSDate(timeIntervalSinceReferenceDate: 100000)
        let mediaInfo = ["course_video": CourseMediaInfo(name: "Video", uri: "http://example.com/image")]
        let startInfo = OEXCourseStartDisplayInfo(date: nil, displayDate: "Eventually", type: .String)
        let course = OEXCourse.freshCourse(
            shortDescription: "This is a course that teaches you completely amazing things that you have always wanted to learn!",
            effort : "Four to six weeks",
            overview: NSString.oex_longTestString(),
            mediaInfo: mediaInfo,
            startInfo: startInfo,
            end: endDate)
        
        let controller = CourseCatalogDetailViewController(environment: environment, courseID: course.course_id!)
        environment.mockNetworkManager.interceptWhenMatching({_ in return true}) {
            return (nil, course)
        }
        inScreenNavigationContext(controller) {
            self.waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func verifyField(
        effort effort : String? = nil,
        shortDescription: String? = nil,
        overview: String? = nil,
        startInfo: OEXCourseStartDisplayInfo? = nil,
        mediaInfo: [String:CourseMediaInfo] = [:],
        endDate: NSDate? = nil,
        file : String = __FILE__, line : UInt = __LINE__,
        verifier : CourseCatalogDetailView -> Bool)
    {
        let course = OEXCourse.freshCourse(
            shortDescription: shortDescription,
            effort : effort,
            overview: overview,
            mediaInfo: mediaInfo,
            startInfo: startInfo,
            end: endDate)
        let environment = TestRouterEnvironment()
        let view = CourseCatalogDetailView(frame: CGRectZero, environment: environment)
        view.applyCourse(course)
        XCTAssertTrue(verifier(view), file:file, line:line)
    }
    
    func testHasEffortField() {
        verifyField(effort:"some effort", endDate: nil) { $0.t_showingEffort }
    }
    
    func testHasNoEffortField() {
        verifyField(effort:nil, endDate: nil) { !$0.t_showingEffort }
    }
    
    func testHasEndFieldNotStarted() {
        verifyField(effort:nil, endDate: NSDate().dateByAddingDays(1)) { $0.t_showingEndDate }
    }
    
    func testHasEndFieldStarted() {
        let startInfo = OEXCourseStartDisplayInfo(date: NSDate().dateByAddingDays(-1), displayDate: nil, type: .Timestamp)
        verifyField(effort:nil, startInfo: startInfo, endDate: NSDate().dateByAddingDays(1)) { !$0.t_showingEndDate }
    }
    
    func testHasNoEndFieldCourseNotStarted() {
        verifyField(effort:nil, endDate: nil) { !$0.t_showingEndDate }
    }
    
    func testShortDescriptionEmpty() {
        verifyField(shortDescription: "") { !$0.t_showingShortDescription }
    }
    
    func testShortDescriptionNotEmpty() {
        verifyField(shortDescription: "ABC") { $0.t_showingShortDescription }
    }
    
    func testCourseOverviewEmpty() {
        verifyField(mediaInfo: [:]) { !$0.t_showingPlayButton }
    }
    
    func testCourseOverviewNotEmpty() {
        let mediaInfo = [
            "course_video" : CourseMediaInfo(name: "course video", uri: "http://example.com/video")
        ]
        verifyField(mediaInfo: mediaInfo) { $0.t_showingPlayButton }
    }
}
