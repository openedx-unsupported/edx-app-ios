//
//  CourseInfoAPI.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 23/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

import edXCore

public struct CourseInfoAPI {
    
    static func handoutsDeserializer(response : HTTPURLResponse, json : JSON) -> Result<String> {
        return json["handouts_html"].string.toResult(NSError.oex_error(with: .handoutsEmpty, message: Strings.handoutsUnavailable))
    }
    
    public static func getHandoutsForCourseWithID(courseID : String, overrideURL: String? = nil) -> NetworkRequest<String> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : overrideURL ?? "api/mobile/v0.5/course_info/\(courseID)/handouts",
            requiresAuth : true,
            deserializer: .jsonResponse(handoutsDeserializer)
        )
    }
}
