//
//  CourseBannerAPI.swift
//  edX
//
//  Created by Muhammad Umer on 18/09/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation
import edXCore

class CourseBannerAPI: NSObject {
    private static func courseBannerDeserializer(response: HTTPURLResponse, json: JSON) -> Result<CourseDateBannerModel> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            return Success(v: CourseDateBannerModel(json: json))
        }
        return Failure()
    }
    
    private class func resetDatePath(courseID: String) -> String {
        return "/api/course_experience/v1/course_deadlines_info/{courseID}".oex_format(withParameters: ["courseID" : courseID])
    }
    
    class func courseBannerRequest(courseID: String) -> NetworkRequest<CourseDateBannerModel> {
        return NetworkRequest(
            method: .GET,
            path : resetDatePath(courseID: courseID),
            requiresAuth : true,
            deserializer: .jsonResponse(courseBannerDeserializer))
    }
    
    private static func courseDateResetDeserializer(response : HTTPURLResponse) -> Result<()> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            return Success(v: ())
            
        }
        return Failure()
    }
    
    private class var datesShiftPath: String {
        return "/api/course_experience/v1/reset_course_deadlines"
    }
    
    class func courseDatesResetRequest(courseID: String)-> NetworkRequest<()> {
        return NetworkRequest(
            method: .POST,
            path : datesShiftPath,
            requiresAuth : true,
            body: .jsonBody(
                JSON(["course_key": courseID])
            ),
            deserializer: .noContent(courseDateResetDeserializer))
    }
}
