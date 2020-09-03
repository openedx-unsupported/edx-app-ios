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
    
    private class func path(courseID: String)-> String {
        return "/api/course_home/v1/dates/{courseID}".oex_format(withParameters: ["courseID" : courseID])
    }
    
    class func courseDatesRequest(courseID: String)-> NetworkRequest<CourseDateModel> {
        let datesPath = path(courseID: courseID)
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : datesPath,
            requiresAuth : true,
            deserializer: .jsonResponse(courseDateDeserializer))
    }
}
