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
    
    static func enrollmentsDeserializer(response: HTTPURLResponse, json: JSON) -> Result<[UserCourseEnrollment]> {
        if json["enrollments"].exists() {
            return (json["enrollments"].array?.compactMap { UserCourseEnrollment(json: $0) }).toResult()
        } else {
            return (json.array?.compactMap { UserCourseEnrollment(json: $0) }).toResult()
        }
    }
    
    static func getUserEnrollments(username: String, organizationCode: String?, config: OEXConfig?) -> NetworkRequest<[UserCourseEnrollment]> {
        let apiVersion = config?.apiUrlVersionConfig.enrollments ?? APIURLDefaultVersion.enrollments.rawValue
        
        var path = "api/mobile/{api_version}/users/{username}/course_enrollments/"
            .oex_format(withParameters: ["username": username, "api_version": apiVersion])
        
        if let orgCode = organizationCode {
            path = "api/mobile/{api_version}/users/{username}/course_enrollments/?org={org}"
                .oex_format(withParameters: ["username": username, "org": orgCode, "api_version": apiVersion])
        }
        
        return NetworkRequest(
            method: .GET,
            path: path,
            requiresAuth: true,
            deserializer: .jsonResponse(enrollmentsDeserializer)
        )
    }
}
