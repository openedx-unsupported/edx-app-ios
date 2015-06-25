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
        let courseVisitedModuleId : String
        let modificationDate = OEXDateFormatting.serverStringWithDate(NSDate())
        var query : [String:String] {
            return [
                "last_visited_module_id" : courseVisitedModuleId,
                "modification_date" : modificationDate
            ]
        }
        
        var jsonBody : JSON {
            return JSON(query)
        }
}

    static func lastAccessedDeserializer(response : NSHTTPURLResponse?, data : NSData?) -> Result<CourseLastAccessed> {        
        return Result(jsonData : data, error : NSError.oex_courseContentLoadError()) {
            return CourseLastAccessed(json: $0)
        }
    }
    
    public static func requestLastVisitedModuleForCourseID(courseID: String) -> NetworkRequest<CourseLastAccessed> {

        return NetworkRequest(
            method: HTTPMethod.GET,
            path : "/api/mobile/v0.5/users/{username}/course_status_info/{course_id}".oex_formatWithParameters(["course_id" : courseID, "username":OEXSession.sharedSession()?.currentUser?.username ?? ""]),
            requiresAuth : true,
            deserializer: lastAccessedDeserializer)
    }
    
    public static func setLastVisitedModuleForBlockID(blockID:String, module_id:String) -> NetworkRequest<CourseLastAccessed> {
        let requestParams = UserStatusParameters(courseVisitedModuleId: module_id)
        
        return NetworkRequest(
            method: HTTPMethod.PATCH,
            path : "/api/mobile/v0.5/users/{username}/course_status_info/{course_id}".oex_formatWithParameters(["course_id" : blockID, "username":OEXSession.sharedSession()?.currentUser?.username ?? ""]),
            requiresAuth : true,
            body : RequestBody.JSONBody(requestParams.jsonBody),
            deserializer: lastAccessedDeserializer)
    }
    



}
