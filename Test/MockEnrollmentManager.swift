//
//  MockEnrollmentManager.swift
//  edX
//
//  Created by Akiva Leffert on 12/27/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

@testable import edX

class MockEnrollmentManager: EnrollmentManager {
    
    private lazy var enrollmentSink : Sink<[UserCourseEnrollment]> = {
        let sink = Sink<[UserCourseEnrollment]>()
        sink.close()
        return sink
    }()
    
    var enrollments: [UserCourseEnrollment] {
        get {
            return enrollmentSink.value ?? []
        }
        set {
            enrollmentSink.send(newValue)
        }
    }
    
    var courses: [OEXCourse] {
        get {
            return enrollments.map { $0.course }
        }
        set {
            enrollments = newValue.map { UserCourseEnrollment(course: $0) }
        }
    }
    
    override func freshFeedWithUsername(username: String) -> Feed<[UserCourseEnrollment]> {
        return Feed {[unowned self] in
            $0.backWithStream(self.enrollmentSink)
            return
        }
    }
}