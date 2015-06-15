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
        let modificationDate = DateUtils.getFormattedDate()
        var query : [String:String] {
            return [
                "last_visited_module_id" : courseVisitedModuleId,
                "modification_date" : modificationDate
            ]
        }
        
        var jsonBody : JSON {
            let jsonData = NSJSONSerialization.dataWithJSONObject(query, options: NSJSONWritingOptions(0), error: nil)
            return JSON(NSString(data: jsonData!, encoding: NSASCIIStringEncoding)!)
            
        }
}

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
    
    public static func setLastVisitedModuleForBlockID(blockID:String, module_id:String) -> NetworkRequest<CourseLastAccessed> {
        let requestParams = UserStatusParameters(courseVisitedModuleId: module_id)
        
        return NetworkRequest(
            method: HTTPMethod.PATCH,
            path : "/api/mobile/v0.5/users/{username}/course_status_info/{course_id}".oex_formatWithParameters(["course_id" : blockID, "username":OEXSession.sharedSession()!.currentUser!.username]),
            requiresAuth : true,
            body : RequestBody.JSONBody(requestParams.jsonBody),
            deserializer: fromData)
    }
    



}
