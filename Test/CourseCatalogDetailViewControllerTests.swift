//
//  CourseCatalogDetailViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX

class CourseCatalogDetailViewControllerTests: SnapshotTestCase {
    
    func setupWithCourse(_ course: OEXCourse, interface: OEXInterface? = nil) -> (TestRouterEnvironment, CourseCatalogDetailViewController) {
        let environment = TestRouterEnvironment(interface: interface).logInTestUser()
        environment.mockEnrollmentManager.enrollments = []
        environment.mockNetworkManager.interceptWhenMatching({_ in true}) {
            return (nil, course)
        }
        
        let controller = CourseCatalogDetailViewController(environment: environment, courseID: course.course_id!)
        return (environment, controller)
    }
    
    // MARK: Snapshots
    
    func testSnapshotAboutScreen() {
        let endDate = NSDate.stableTestDate()
        let mediaInfo = ["course_video": CourseMediaInfo(name: "Video", uri: "http://example.com/image")]
        let startInfo = OEXCourseStartDisplayInfo(date: nil, displayDate: "Eventually", type: .string)
        let course = OEXCourse.freshCourse(
            shortDescription: "This is a course that teaches you completely amazing things that you have always wanted to learn!",
            overview: NSString.oex_longTest(),
            effort : "Four to six weeks",
            mediaInfo: mediaInfo,
            startInfo: startInfo,
            end: endDate as NSDate)
        let (_, controller) = setupWithCourse(course)
        inScreenNavigationContext(controller) {
            self.waitForStream(controller.t_loaded)
            stepRunLoop()
            self.assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    // MARK: Course Content
    
    func verifyField(
        effort : String? = nil,
        shortDescription: String? = nil,
        overview: String? = nil,
        startInfo: OEXCourseStartDisplayInfo? = nil,
        mediaInfo: [String:CourseMediaInfo] = [:],
        endDate: NSDate? = nil,
        file : StaticString = #file, line : UInt = #line,
        verifier : (CourseCatalogDetailView) -> Bool)
    {
        let course = OEXCourse.freshCourse(
            shortDescription: shortDescription,
            overview: overview,
            effort : effort,
            mediaInfo: mediaInfo,
            startInfo: startInfo,
            end: endDate)
        let environment = TestRouterEnvironment()
        let view = CourseCatalogDetailView(frame: CGRect.zero, environment: environment)
        view.applyCourse(course: course)
        XCTAssertTrue(verifier(view), file:file, line:line)
    }
    
    func testHasEffortField() {
        verifyField(effort:"some effort", endDate: nil) { $0.t_showingEffort }
    }
    
    func testHasNoEffortField() {
        verifyField(effort:nil, endDate: nil) { !$0.t_showingEffort }
    }
    
    func testHasEndFieldNotStarted() {
        verifyField(effort:nil, endDate: NSDate().addingDays(1)! as NSDate) { $0.t_showingEndDate }
    }
    
    func testHasEndFieldStarted() {
        let startInfo = OEXCourseStartDisplayInfo(date: NSDate().addingDays(-1), displayDate: nil, type: .timestamp)
        verifyField(effort:nil, startInfo: startInfo, endDate: NSDate().addingDays(1)! as NSDate) { !$0.t_showingEndDate }
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
        environment.mockEnrollmentManager.enrollments = []
        
        // load the course
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            
            // try to enroll with a bad request
            environment.mockNetworkManager.interceptWhenMatching({(_ : NetworkRequest<UserCourseEnrollment>) in return true}, statusCode: 401, error: NSError.oex_unknownError())
            
            let expectations = expectation(description: "enrollment finishes")
            controller.t_enrollInCourse(completion: { () -> Void in
                XCTAssertTrue(controller.t_isShowingOverlayMessage)
                expectations.fulfill()
            })
            waitForExpectations()
            
        }
    }
    
    @discardableResult func verifyEnrollmentSuccessWithCourse(_ course: OEXCourse, message: String, setupEnvironment: ((TestRouterEnvironment) -> Void)? = nil) -> TestRouterEnvironment {
        let (environment, controller) = setupWithCourse(course)
        environment.mockEnrollmentManager.enrollments = []
        setupEnvironment?(environment)
        
        inScreenDisplayContext(controller) {
            // load the course
            waitForStream(controller.t_loaded)
            
            // try to enroll
            environment.mockNetworkManager.interceptWhenMatching({_ in true}) {
                return (nil, UserCourseEnrollment(course:course, isActive: true))
            }
            
            expectation(forNotification: EnrollmentShared.successNotification, object: nil, handler: { (notification) -> Bool in
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
            return event.event.name == AnalyticsEventName.CourseEnrollment.rawValue
        })
        XCTAssertNotNil(index)
    }
    
    func testShowsViewCourseWhenEnrolled() {
        let course = OEXCourse.freshCourse()
        let (environment, controller) = setupWithCourse(course)
        environment.mockEnrollmentManager.courses = [course]
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            XCTAssertEqual(controller.t_actionText!, Strings.CourseDetail.viewCourse)
        }
    }
    
    func testShowsEnrollWhenNotEnrolled() {
        let course = OEXCourse.freshCourse()
        let (_, controller) = setupWithCourse(course)
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            XCTAssertEqual(controller.t_actionText!, Strings.CourseDetail.enrollNow)
        }
    }
}
