//
//  CoursesAPI.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore

struct CoursesAPI {
    
    static func enrollmentsDeserializer(response: NSHTTPURLResponse, json: JSON) -> Result<[UserCourseEnrollment]> {
        return (json.array?.flatMap { UserCourseEnrollment(json: $0) }).toResult()
    }
    
    static func getUserEnrollments(username: String, organizationCode: String?) -> NetworkRequest<[UserCourseEnrollment]> {
        var path = "api/mobile/v0.5/users/{username}/course_enrollments/".oex_formatWithParameters(["username": username])
        if let orgCode = organizationCode {
            if (!(orgCode ?? "").isEmpty) {
                path = "api/mobile/v0.5/users/{username}/course_enrollments/?org={org}".oex_formatWithParameters(["username": username, "org": organizationCode!])
            }
        }
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .JSONResponse(enrollmentsDeserializer)
        )
    }
}