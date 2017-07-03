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
    private let config: OEXConfig
    
    public init(interface: OEXInterface?, networkManager: NetworkManager, config: OEXConfig) {
        self.interface = interface
        self.networkManager = networkManager
        self.config = config
        
        super.init()
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) in
            observer.clearFeed()
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionStarted.rawValue) { (notification, observer, _) -> Void in
            
            if let userDetails = notification.userInfo?[OEXSessionStartedUserDetailsKey] as? OEXUserDetails {
                observer.setupFeedWithUserDetails(userDetails: userDetails)
            }
        }
        
        // Eventutally we should remove responsibility for knowing about the course list
        // from OEXInterface and remove these
        feed.output.listen(self) {[weak self] enrollments in
            enrollments.ifSuccess {
                let courses = $0?.flatMap { $0.course } ?? []
                self?.interface?.setRegisteredCourses(courses)
                self?.interface?.deleteUnregisteredItems()
                self?.interface?.t_setCourseEnrollments($0 ?? [])
            }
        }
    }
    
    public var feed: Feed<[UserCourseEnrollment]?> {
        return enrollmentFeed
    }
    
    public func enrolledCourseWithID(courseID: String) -> UserCourseEnrollment? {
        return self.streamForCourseWithID(courseID: courseID).value
    }
    
    public func streamForCourseWithID(courseID: String) -> OEXStream<UserCourseEnrollment> {
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
            stream.send(Success(v: nil))
        }
        self.enrollmentFeed.backWithFeed(feed: feed)
        
        self.enrollmentFeed.refresh()
    }
    
    private func setupFeedWithUserDetails(userDetails: OEXUserDetails) {
        guard let username = userDetails.username else { return }
        let organizationCode = self.config.organizationCode()
        let feed = freshFeedWithUsername(username: username, organizationCode: organizationCode)
        enrollmentFeed.backWithFeed(feed: feed.map {x in x})
        enrollmentFeed.refresh()
    }
    
    func freshFeedWithUsername(username: String, organizationCode: String?) -> Feed<[UserCourseEnrollment]> {
        let request = CoursesAPI.getUserEnrollments(username: username, organizationCode: organizationCode)
        return Feed(request: request, manager: networkManager, persistResponse: true)
    }
}
