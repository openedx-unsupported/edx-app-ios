//
//  CourseCatalogAPI.swift
//  edX
//
//  Created by Anna Callahan on 10/14/15.
//  Copyright © 2015 edX. All rights reserved.
//


public struct CourseCatalogAPI {
    
    static func coursesDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<Paginated<[OEXCourse]>> {
        let result = Paginated(json: json) {body in
            body.array?.flatMap {item in
                item.dictionaryObject.map { OEXCourse(dictionary: $0) }
            }
        }
        return result.toResult()
    }
    
    static func courseDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<OEXCourse> {
        return json.dictionaryObject.map { OEXCourse(dictionary: $0) }.toResult()
    }
    
    static func enrollmentDeserializer(response: NSHTTPURLResponse, json: JSON) -> Result<UserCourseEnrollment> {
        return UserCourseEnrollment(json: json).toResult()
    }
    
    private enum Params : String {
        case User = "user"
        case CourseDetails = "course_details"
        case CourseID = "course_id"
        case EmailOptIn = "email_opt_in"
    }
    
    public static func getCourseCatalog(userID: String, page : Int) -> NetworkRequest<Paginated<[OEXCourse]>> {
        return NetworkRequest(
            method: .GET,
            path : "api/courses/v1/courses/",
            query : [
                Params.User.rawValue: JSON(userID),
                PaginationDefaults.pageParam: JSON(page)
            ],
            requiresAuth : true,
            deserializer: .JSONResponse(coursesDeserializer)
        )
    }
    
    public static func getCourse(courseID: String) -> NetworkRequest<OEXCourse> {
        return NetworkRequest(
            method: .GET,
            path: "api/courses/v1/courses/{courseID}".oex_formatWithParameters(["courseID" : courseID]),
            requiresAuth : true,
            deserializer: .JSONResponse(courseDeserializer))
    }
    
    public static func enroll(courseID: String, emailOptIn: Bool = true) -> NetworkRequest<UserCourseEnrollment> {
        return NetworkRequest(
            method: .POST,
            path: "api/enrollment/v1/enrollment",
            requiresAuth: true,

            query: [
                "course_details" : [
                    "course_id": courseID,
                    "email_opt_in": emailOptIn
                ]
            ],
            deserializer: .JSONResponse(enrollmentDeserializer)
        )
    }
}