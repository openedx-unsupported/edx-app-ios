//
//  CourseDashboardViewControllerTests.swift
//  edX
//
//  Created by Salman on 01/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
import edXCore
@testable import edX

private extension OEXConfig {
    
    convenience init(courseVideosEnabled: Bool = false, courseDatesEnabled: Bool = true, discussionsEnabled : Bool, courseSharingEnabled: Bool = false, isAnnouncementsEnabled: Bool = true, tabDashboardEnabled: Bool = true, certificatesEnabled: Bool = false) {
        self.init(dictionary: [
            "COURSE_VIDEOS_ENABLED" : courseVideosEnabled,
            "COURSE_DATES_ENABLED" : courseDatesEnabled,
            "DISCUSSIONS_ENABLED": discussionsEnabled,
            "COURSE_SHARING_ENABLED": courseSharingEnabled,
            "ANNOUNCEMENTS_ENABLED": isAnnouncementsEnabled,
            "TAB_LAYOUTS_ENABLED": tabDashboardEnabled,
            "CERTIFICATES_ENABLED": certificatesEnabled
            ]
        )
    }
}

class CourseDashboardViewControllerTests: SnapshotTestCase {
    
    func testDiscussionsEnabled() {
        for enabledInConfig in [true, false] {
            for enabledInCourse in [true, false] {
                
                let config = OEXConfig(discussionsEnabled: enabledInConfig)
                let course = OEXCourse.freshCourse(discussionsEnabled: enabledInCourse)
                let environment = TestRouterEnvironment(config: config)
                environment.mockEnrollmentManager.courses = [course]
                environment.logInTestUser()
                let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
                
                inScreenDisplayContext(controller) {
                    waitForStream(controller.t_loaded)
                    
                    let enabled = controller.t_canVisitDiscussions()
                    
                    let expected = enabledInConfig && enabledInCourse
                    XCTAssertEqual(enabled, expected, "Expected discussion visiblity \(expected) when enabledInConfig: \(enabledInConfig), enabledInCourse:\(enabledInCourse)")
                }
            }
        }
    }

    func testHandoutsEnabled() {
        for hasHandoutsUrl in [true, false] {
            let config = OEXConfig(discussionsEnabled: true)
            let course = OEXCourse.freshCourse(discussionsEnabled: true, hasHandoutsUrl: hasHandoutsUrl)
            let environment = TestRouterEnvironment(config: config)
            environment.mockEnrollmentManager.courses = [course]
            environment.logInTestUser()
            let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
            
            inScreenDisplayContext(controller) {
                waitForStream(controller.t_loaded)
                
                let enabled = controller.t_canVisitHandouts()
                
                let expected = hasHandoutsUrl
                XCTAssertEqual(enabled, expected, "Expected handouts visiblity \(expected) when course_handouts_empty: \(hasHandoutsUrl)")
            }
        }
    }
    
    func testAnnouncementsEnabled() {
        for isAnnouncementsEnabled in [true, false] {
            let config = OEXConfig(discussionsEnabled: true, isAnnouncementsEnabled:isAnnouncementsEnabled)
            let course = OEXCourse.freshCourse(discussionsEnabled: true)
            let environment = TestRouterEnvironment(config: config)
            environment.mockEnrollmentManager.courses = [course]
            environment.logInTestUser()
            let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
            
            inScreenDisplayContext(controller) {
                waitForStream(controller.t_loaded)
                
                let enabled = controller.t_canVisitAnnouncements()
                
                let expected = isAnnouncementsEnabled
                XCTAssertEqual(enabled, expected, "Expected announcements visiblity \(expected) when is_announcements_enabled: \(isAnnouncementsEnabled)")
            }
        }
    }
    
    func testSnapshot() {
        let config = OEXConfig(courseVideosEnabled: true, courseDatesEnabled: true, discussionsEnabled: true, courseSharingEnabled: true, isAnnouncementsEnabled: true, tabDashboardEnabled: true)
        let course = OEXCourse.freshCourse(aboutUrl: "http://www.yahoo.com")
        let outline = CourseOutlineTestDataFactory.freshCourseOutline(course.course_id!)
        let interface = OEXInterface.shared()
        let environment = TestRouterEnvironment(config: config, interface: interface)
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: outline.root, interface: interface, outline: outline)
        environment.interface?.t_setCourseEnrollments([UserCourseEnrollment(course: course)])
        environment.interface?.t_setCourseVideos([course.course_id!: OEXVideoSummaryTestDataFactory.localCourseVideos(CourseOutlineTestDataFactory.knownLocalVideoID)])
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
    
        let stream = environment.mockCourseDataManager.querier?.childrenOfBlockWithID(blockID: outline.root, forMode: .full)
        
        let expectations = expectation(description: "course loaded")
        stream?.listenOnce(self) {_ in
            expectations.fulfill()
        }
        
        waitForExpectations()
        
        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testCertificate() {
        let config = OEXConfig(courseVideosEnabled: true, courseDatesEnabled: true, discussionsEnabled: true, courseSharingEnabled: true, isAnnouncementsEnabled: true, tabDashboardEnabled: true, certificatesEnabled: true)
        
        let courseData = OEXCourse.testData()
        let course = OEXCourse(dictionary: courseData)
        
        let outline = CourseOutlineTestDataFactory.freshCourseOutline(course.course_id!)
        let interface = OEXInterface.shared()
        let enrollment = UserCourseEnrollment(dictionary: ["certificate":["url":"test"], "course" : courseData])!
        
        interface.t_setCourseVideos([course.course_id!: OEXVideoSummaryTestDataFactory.localCourseVideos(CourseOutlineTestDataFactory.knownLocalVideoID)])
        
        let environment = TestRouterEnvironment(config: config, interface: interface).logInTestUser()
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: outline.root, interface: interface, outline: outline)
        environment.mockEnrollmentManager.courses = [course]
        environment.mockEnrollmentManager.enrollments = [enrollment]
        
        
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        
        let stream = environment.mockCourseDataManager.querier?.childrenOfBlockWithID(blockID: outline.root, forMode: .full)
        
        let expectations = expectation(description: "course loaded")
        stream?.listenOnce(self) {_ in
            expectations.fulfill()
        }
        
        waitForExpectations()
        
        
        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    
    func testResourcesViewSnapshot() {
        let config = OEXConfig(courseVideosEnabled: true, courseDatesEnabled: true, discussionsEnabled: true, courseSharingEnabled: true, isAnnouncementsEnabled: true)
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment(config: config)
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        
        let additionalController = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        additionalController.selectedIndex = 4
        
        inScreenNavigationContext(additionalController, action: { () -> () in
            assertSnapshotValidWithContent(additionalController.navigationController!)
        })
    }
    
    func testDatesViewSnapshot() {
        let config = OEXConfig(courseVideosEnabled: true, courseDatesEnabled: true, discussionsEnabled: true, courseSharingEnabled: true, isAnnouncementsEnabled: true)
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment(config: config)
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        
        let additionalController = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        additionalController.selectedIndex = 3
        
        if let selectedViewController = additionalController.selectedViewController as? CourseDatesViewController,
            let data = CourseDateModel(json: JSON(parseJSON: datesJsonString)) {
            selectedViewController.t_loadData(data: data)
        }
        
        inScreenNavigationContext(additionalController, action: { () -> () in
            assertSnapshotValidWithContent(additionalController.navigationController!)
        })
    }
    
    func testAccessOkay() {
        let course = OEXCourse.freshCourse()
        let environment = TestRouterEnvironment()
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            XCTAssertTrue(controller.t_state.isLoaded)
        }
    }
    
    func testAccessBlocked() {
        let course = OEXCourse.freshCourse(accessible: false)
        let environment = TestRouterEnvironment()
        environment.mockEnrollmentManager.courses = [course]
        environment.logInTestUser()
        let controller = CourseDashboardViewController(environment: environment, courseID: course.course_id!)
        inScreenDisplayContext(controller) {
            waitForStream(controller.t_loaded)
            XCTAssertTrue(controller.t_state.isError)
        }
    }
}

private var datesJsonString: String {
       return """
       {
           "course_date_blocks": [
               {
                   "date": "2020-05-01T17:59:41Z",
                   "date_type": "course-start-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "",
                   "title": "Course Starts"
               },
               {
                   "complete": true,
                   "date": "2020-05-04T02:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "title": "Multi Badges Completed"
               },
               {
                   "date": "2020-05-05T02:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "title": "Multi Badges Past Due"
               },
               {
                   "date": "2020-05-27T02:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "Both Past Due 1"
               },
               {
                   "date": "2020-05-27T02:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "Both Past Due 2"
               },
               {
                   "complete": true,
                   "date": "2020-05-28T08:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "One Completed/Due 1"
               },
               {
                   "date": "2020-05-28T08:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "One Completed/Due 2"
               },
               {
                   "complete": true,
                   "date": "2020-05-29T08:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "Both Completed 1"
               },
               {
                   "complete": true,
                   "date": "2020-05-29T08:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "Both Completed 2"
               },
               {
                   "date": "2020-06-16T17:59:40.942669Z",
                   "date_type": "verified-upgrade-deadline",
                   "description": "Don't miss the opportunity to highlight your new knowledge and skills by earning a verified certificate.",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "Upgrade to Verified Certificate"
               },
               {
                   "date": "2030-08-17T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": false,
                   "link": "https://example.com/",
                   "title": "One Verified 1"
               },
               {
                   "date": "2030-08-17T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "One Verified 2"
               },
               {
                   "date": "2030-08-18T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": false,
                   "link": "https://example.com/",
                   "title": "Both Verified 1"
               },
               {
                   "date": "2030-08-18T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": false,
                   "link": "https://example.com/",
                   "title": "Both Verified 2"
               },
               {
                   "date": "2030-08-19T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "title": "One Unreleased 1"
               },
               {
                   "date": "2030-08-19T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "https://example.com/",
                   "title": "One Unreleased 2"
               },
               {
                   "date": "2030-08-20T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "title": "Both Unreleased 1"
               },
               {
                   "date": "2030-08-20T05:59:40.942669Z",
                   "date_type": "assignment-due-date",
                   "description": "",
                   "learner_has_access": true,
                   "title": "Both Unreleased 2"
               },
               {
                   "date": "2030-08-23T00:00:00Z",
                   "date_type": "course-end-date",
                   "description": "",
                   "learner_has_access": true,
                   "link": "",
                   "title": "Course Ends"
               },
               {
                   "date": "2030-09-01T00:00:00Z",
                   "date_type": "verification-deadline-date",
                   "description": "You must successfully complete verification before this date to qualify for a Verified Certificate.",
                   "learner_has_access": false,
                   "link": "https://example.com/",
                   "title": "Verification Deadline"
               }
           ],
           "display_reset_dates_text": false,
           "learner_is_verified": false,
           "user_timezone": "America/New_York",
           "verified_upgrade_link": "https://example.com/"
       }
       """
   }
