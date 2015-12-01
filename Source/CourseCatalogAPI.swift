//
//  CourseCatalogAPI.swift
//  edX
//
//  Created by Anna Callahan on 10/14/15.
//  Copyright © 2015 edX. All rights reserved.
//


public struct CourseCatalogAPI {
    
    static func coursesDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<[OEXCourse]> {
        return (json.array?.flatMap { (item:JSON) -> OEXCourse? in
            item.dictionaryObject.map { OEXCourse(dictionary: $0) }
        }).toResult()
    }
    
    private enum Params : String {
        case User = "user"
        case CourseDetails = "course_details"
        case CourseID = "course_id"
        case EmailOptIn = "email_opt_in"
    }
    
    public static func getCourseCatalog(userID: String) -> NetworkRequest<[OEXCourse]> {
        return NetworkRequest<[OEXCourse]>(
            method: .GET,
            path : "api/courses/v1/courses/",
            query : [Params.User.rawValue: JSON(userID)],
            requiresAuth : true,
            deserializer: .JSONResponse(coursesDeserializer)
        )
    }
}