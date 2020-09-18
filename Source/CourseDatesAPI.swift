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
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : courseDatesPath(courseID: courseID),
            requiresAuth : true,
            deserializer: .jsonResponse(courseDateDeserializer))
    }
    
    private static func courseDeadlineInfoDeserializer(response: HTTPURLResponse, json: JSON) -> Result<CourseDateInfoBannerModel> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            return Success(v: CourseDateInfoBannerModel(json: json))
        }
        return Failure()
    }
    
    private class func resetDatePath(courseID: String) -> String {
        return "/api/course_experience/v1/course_deadlines_info/{courseID}".oex_format(withParameters: ["courseID" : courseID])
    }
    
    class func courseDeadlineInfoRequest(courseID: String) -> NetworkRequest<CourseDateInfoBannerModel> {
        return NetworkRequest(
            method: .GET,
            path : resetDatePath(courseID: courseID),
            requiresAuth : true,
            deserializer: .jsonResponse(courseDeadlineInfoDeserializer))
    }
    
    private static func courseResetDeadlineDeserializer(response : HTTPURLResponse) -> Result<()> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            return Success(v: ())
            
        }
        return Failure()
    }
    
    private class var datesResetPath: String {
        return "/api/course_experience/v1/reset_course_deadlines"
    }
    
    class func courseResetDeadlineRequest(courseID: String)-> NetworkRequest<()> {
        return NetworkRequest(
            method: .POST,
            path : datesResetPath,
            requiresAuth : true,
            body: .jsonBody(
                JSON(["course_key": courseID])
            ),
            deserializer: .noContent(courseResetDeadlineDeserializer))
    }
}
