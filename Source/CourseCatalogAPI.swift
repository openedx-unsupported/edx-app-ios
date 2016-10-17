//
//  CourseCatalogAPI.swift
//  edX
//
//  Created by Anna Callahan on 10/14/15.
//  Copyright © 2015 edX. All rights reserved.
//

import edXCore

public struct CourseCatalogAPI {
    
    static func coursesDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<[OEXCourse]> {
        return (json.array?.flatMap {item in
            item.dictionaryObject.map { OEXCourse(dictionary: $0) }
        }).toResult()
    }
    
    static func courseDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<OEXCourse> {
        return json.dictionaryObject.map { OEXCourse(dictionary: $0) }.toResult()
    }
    
    static func enrollmentDeserializer(response: NSHTTPURLResponse, json: JSON) -> Result<UserCourseEnrollment> {
        return UserCourseEnrollment(json: json).toResult()
    }
    
    private enum Params : String {
        case User = "username"
        case CourseDetails = "course_details"
        case CourseID = "course_id"
        case EmailOptIn = "email_opt_in"
        case Mobile = "mobile"
        case Org = "org"
    }
    
    public static func getCourseCatalog(userID: String, page : Int, organizationCode: String?) -> NetworkRequest<Paginated<[OEXCourse]>> {
        var query = [Params.Mobile.rawValue: JSON(true), Params.User.rawValue: JSON(userID)]
        
        if let orgCode = organizationCode {
            if (!(orgCode ?? "").isEmpty) {
                query[Params.Org.rawValue] = JSON(organizationCode!)
            }
        }
        
        return NetworkRequest(
            method: .GET,
            path : "api/courses/v1/courses/",
            query : query,
            requiresAuth : true,
            deserializer: .JSONResponse(coursesDeserializer)
        ).paginated(page: page)
    }
    
    public static func getCourse(courseID: String) -> NetworkRequest<OEXCourse> {
        return NetworkRequest(
            method: .GET,
            path: "api/courses/v1/courses/{courseID}".oex_formatWithParameters(["courseID" : courseID]),
            deserializer: .JSONResponse(courseDeserializer))
    }
    
    public static func enroll(courseID: String, emailOptIn: Bool = true) -> NetworkRequest<UserCourseEnrollment> {
        return NetworkRequest(
            method: .POST,
            path: "api/enrollment/v1/enrollment",
            requiresAuth: true,

            body: .JSONBody(JSON([
                "course_details" : [
                    "course_id": courseID,
                    "email_opt_in": emailOptIn
                ]
            ])),
            deserializer: .JSONResponse(enrollmentDeserializer)
        )
    }
}