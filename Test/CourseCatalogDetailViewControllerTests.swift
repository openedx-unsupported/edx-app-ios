//
//  CourseCatalogDetailViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX

class CourseCatalogDetailViewControllerTests: SnapshotTestCase {
    
    func setupWithCourse(course: OEXCourse, interface: OEXInterface? = nil) -> (TestRouterEnvironment, CourseCatalogDetailViewController) {
        let environment = TestRouterEnvironment(interface: interface)
        environment.mockNetworkManager.interceptWhenMatching({_ in true}) {
            return (nil, course)
        }
        
        let controller = CourseCatalogDetailViewController(environment: environment, courseID: course.course_id!)
        return (environment, controller)
    }
    
    // MARK: Snapshots
    
    func testSnapshotAboutScreen() {
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
        let (_, controller) = setupWithCourse(course)
        inScreenNavigationContext(controller) {
            self.waitForStream(controller.t_loaded)
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    // MARK: Course Content
    
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
    
    // MARK: Enrollment
    
    func testEnrollmentFailureShowsError() {
        let course = OEXCourse.freshCourse()
        let (environment, controller) = setupWithCourse(course)
        
        // load the course
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            
            // try to enroll with a bad request
            environment.mockNetworkManager.interceptWhenMatching({(_ : NetworkRequest<UserCourseEnrollment>) in return true}, statusCode: 401, error: NSError.oex_unknownError())
            
            let expectation = expectationWithDescription("enrollment finishes")
            controller.t_enrollInCourse({ () -> Void in
                XCTAssertTrue(controller.t_isShowingOverlayMessage)
                expectation.fulfill()
            })
            waitForExpectations()
            
        }
    }
    
    func verifyEnrollmentSuccessWithCourse(course: OEXCourse, message: String, setupEnvironment: (TestRouterEnvironment -> Void)? = nil) -> TestRouterEnvironment {
        let (environment, controller) = setupWithCourse(course)
        setupEnvironment?(environment)
        
        inScreenDisplayContext(controller) {
            // load the course
            waitForStream(controller.t_loaded)
            
            // try to enroll
            environment.mockNetworkManager.interceptWhenMatching({_ in true}) {
                return (nil, UserCourseEnrollment(course:course, isActive: true))
            }
            
            expectationForNotification(EnrollmentShared.successNotification, object: nil, handler: { (notification) -> Bool in
                let enrollmentMessage = notification.object as! String
                return enrollmentMessage == message
            })
            var completionCalled = false
            controller.t_enrollInCourse {
                completionCalled = true
            }
            waitForExpectations()
            XCTAssertTrue(completionCalled)
        }
        return environment
    }
    
    
    func testEnrollmentRecognizesAlreadyEnrolled() {
        let course = OEXCourse.freshCourse()
        self.verifyEnrollmentSuccessWithCourse(course, message: Strings.findCoursesAlreadyEnrolledMessage) {env in
            env.mockEnrollmentManager.courses = [course]
            env.logInTestUser()
            env.mockEnrollmentManager.feed.refresh()
        }
    }
    
    func testEnrollmentNewEnrollment() {
        let environment = verifyEnrollmentSuccessWithCourse(OEXCourse.freshCourse(), message: Strings.findCoursesEnrollmentSuccessfulMessage)

        // and make sure the event fires
        let index: Int? = environment.eventTracker.events.firstIndexMatching({ (record: MockAnalyticsRecord) -> Bool in
            guard let event = record.asEvent else {
                return false
            }
            return event.event.name == OEXAnalyticsEventCourseEnrollment
        })
        XCTAssertNotNil(index)
    }
}
