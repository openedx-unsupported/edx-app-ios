//
//  UserAPI.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public struct UserAPI {
    public struct UserStatusParameters {
        let courseId : String
        var query : [String:JSON] {
            return [
                "course_id" : JSON(courseId)
            ]
        }
}
//
    static func fromData(response : NSHTTPURLResponse?, data : NSData?) -> Result<CourseLastAccessed> {
        return data.toResult(nil).flatMap {data -> Result<AnyObject> in
            var error : NSError? = nil
            let result : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &error)
            return result.toResult(error)
            }.flatMap {json in
                return CourseLastAccessed(json: JSON(json)).toResult(NSError.oex_unknownError())
        }
    }
    
    public static func requestLastVisitedModuleForCourseID(courseID: String) -> NetworkRequest<CourseLastAccessed> {

        return NetworkRequest(
            method: HTTPMethod.GET,
            path : "/api/mobile/v0.5/users/{username}/course_status_info/{course_id}".oex_formatWithParameters(["course_id" : courseID, "username":OEXSession.sharedSession()!.currentUser!.username]),
            deserializer: fromData)
    }
    



}
