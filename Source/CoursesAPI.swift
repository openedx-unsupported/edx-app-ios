//
//  CoursesAPI.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

struct CoursesAPI {
    
    static func enrollmentsDeserializer(response: NSHTTPURLResponse, json: JSON) -> Result<[UserCourseEnrollment]> {
        return (json.array?.flatMap { UserCourseEnrollment(json: $0) }).toResult()
    }
    
    static func getUserEnrollments(username: String) -> NetworkRequest<[UserCourseEnrollment]> {
        return NetworkRequest(
            method: .GET,
            path: "api/mobile/v0.5/users/{username}/course_enrollments/".oex_formatWithParameters(["username": username]),
            requiresAuth: true,
            deserializer: .JSONResponse(enrollmentsDeserializer)
        )
    }
}