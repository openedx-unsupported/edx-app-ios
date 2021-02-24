//
//  CelebratoryAPI.swift
//  edX
//
//  Created by Salman on 27/01/2021.
//  Copyright © 2021 edX. All rights reserved.
//

public struct CelebratoryAPI {
    
    private static func celebratoryModalViewStatusDeserializer(response: HTTPURLResponse, json: JSON) -> Result<CourseCelebrationModel> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            return Success(v: CourseCelebrationModel(json: json))
        }
        return Failure()
    }
    
    private static func celebratoryModalViewDeserializer(response : HTTPURLResponse) -> Result<()> {
        guard response.httpStatusCode.is2xx else {
            return Failure()
        }

        return Success(v: ())
    }

     static func celebratoryModalViewed(username: String, courseID: String, isFirstSectionViewed: Bool) -> NetworkRequest<()> {
        let body = RequestBody.jsonBody(JSON([
                "first_section": isFirstSectionViewed,
            ]))

        return NetworkRequest(
            method: .POST,
            path: "/api/courseware/celebration/{courseID}".oex_format(withParameters: ["courseID" : courseID]),
            requiresAuth: true,
            body: body,
            deserializer: .noContent(celebratoryModalViewDeserializer)
        )
    }
    
    static func celebrationModalViewedStatus(courseID: String) -> NetworkRequest<CourseCelebrationModel> {
        return NetworkRequest(
            method: .GET,
            path: "/api/courseware/course/{courseID}".oex_format(withParameters: ["courseID" : courseID]),
            requiresAuth: true,
            deserializer: .jsonResponse(celebratoryModalViewStatusDeserializer)
        )
    }
}
