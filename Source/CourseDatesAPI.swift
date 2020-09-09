//
//  CourseDatesAPI.swift
//  edX
//
//  Created by Muhammad Umer on 01/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation
import edXCore

public class CourseDatesAPI: NSObject {
    
    private static func courseDateDeserializer(response: HTTPURLResponse, json: JSON) -> Result<CourseDateModel> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            let courseDatesModel = CourseDateModel(json: json)
            return Success(v: courseDatesModel)
        }
        return Failure(e: NSError(domain: "CourseDatesErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: Strings.Coursedates.courseDateUnavailable]))
    }
    
    private class func courseDatesPath(courseID: String)-> String {
        return "/api/course_home/v1/dates/{courseID}".oex_format(withParameters: ["courseID" : courseID])
    }
    
    class func courseDatesRequest(courseID: String)-> NetworkRequest<CourseDateModel> {
        let datesPath = courseDatesPath(courseID: courseID)
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : datesPath,
            requiresAuth : true,
            deserializer: .jsonResponse(courseDateDeserializer))
    }
    
    private static func courseDeadlineDeserializer(response: HTTPURLResponse, json: JSON) -> Result<CourseDeadline> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            let courseDeadlineModel = CourseDeadline(json: json)
            return Success(v: courseDeadlineModel)
        }
        return Failure()
    }
    
    private class func courseDeadlinePath(courseID: String)-> String {
        return "/api/course_experience/v1/course_deadlines_info/{courseID}".oex_format(withParameters: ["courseID" : courseID])
    }
    
    class func courseDeadlineRequest(courseID: String)-> NetworkRequest<CourseDeadline> {
        let datesPath = courseDeadlinePath(courseID: courseID)
        return NetworkRequest(
            method: .GET,
            path : datesPath,
            requiresAuth : true,
            deserializer: .jsonResponse(courseDeadlineDeserializer))
    }
}
