//
//  EnrollmentManager.swift
//  edX
//
//  Created by Akiva Leffert on 12/26/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public class EnrollmentManager : NSObject {
    private let interface: OEXInterface?
    private let networkManager : NetworkManager
    private let enrollmentFeed = BackedFeed<[UserCourseEnrollment]?>()
    
    public init(interface: OEXInterface?, networkManager: NetworkManager) {
        self.interface = interface
        self.networkManager = networkManager
        
        super.init()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXSessionEndedNotification) { (_, observer, _) in
            observer.clearFeed()
        }
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXSessionStartedNotification) { (notification, observer, _) -> Void in
            
            if let userDetails = notification.userInfo?[OEXSessionStartedUserDetailsKey] as? OEXUserDetails {
                observer.setupFeedWithUserDetails(userDetails)
            }
        }
        
        // Eventutally we should remove responsibility for knowing about the course list
        // from OEXInterface and remove these
        feed.output.listen(self) {[weak self] enrollments in
            enrollments.ifSuccess {
                let courses = $0?.flatMap { $0.course } ?? []
                self?.interface?.setRegisteredCourses(courses)
                self?.interface?.deleteUnregisteredItems()
                self?.interface?.courses = $0 ?? []
            }
        }
    }
    
    public var feed: Feed<[UserCourseEnrollment]?> {
        return enrollmentFeed
    }
    
    public func enrolledCourseWithID(courseID: String) -> UserCourseEnrollment? {
        return self.enrollmentStreamForCourseWithID(courseID).value
    }
    
    public func enrollmentStreamForCourseWithID(courseID: String) -> Stream<UserCourseEnrollment> {
        let hasCourse = enrollmentFeed.output.value??.contains {
            $0.course.course_id == courseID
            } ?? false
        
        if !hasCourse {
            enrollmentFeed.refresh()
        }
        
        let courseStream = feed.output.flatMap(fireIfAlreadyLoaded: hasCourse || !enrollmentFeed.output.active) { enrollments in
            return enrollments.toResult().flatMap { enrollments -> Result<UserCourseEnrollment> in
                let courseEnrollment = enrollments.firstObjectMatching {
                    return $0.course.course_id == courseID
                }
                return courseEnrollment.toResult()
            }
        }
        
        return courseStream
    }
    
    private func clearFeed() {
        let feed = Feed<[UserCourseEnrollment]?> { stream in
            stream.removeAllBackings()
            stream.send(Success(nil))
        }
        self.enrollmentFeed.backWithFeed(feed)
        
        self.enrollmentFeed.refresh()
    }
    
    private func setupFeedWithUserDetails(userDetails: OEXUserDetails) {
        guard let username = userDetails.username else { return }
        let feed = freshFeedWithUsername(username)
        enrollmentFeed.backWithFeed(feed.map {x in x})
    }
    
    func freshFeedWithUsername(username: String) -> Feed<[UserCourseEnrollment]> {
        let request = CoursesAPI.getUserEnrollments(username)
        return Feed(request: request, manager: networkManager, persistResponse: true)
    }
}