//
//  UserAPI.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import edXCore

public struct UserAPI {
    public struct UserStatusParameters {
        let courseVisitedModuleId : String
        let modificationDate = DateFormatting.serverString(withDate: NSDate()) ?? ""
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

    private static func lastAccessedDeserializer(response : HTTPURLResponse, json : JSON) -> Result<CourseLastAccessed> {
        return CourseLastAccessed(json: json).toResult()
    }
    
    public static func requestLastVisitedModuleForCourseID(courseID: String, version: String) -> NetworkRequest<CourseLastAccessed> {
        let paremeters = [
            "version": version,
            "courseID": courseID,
            "username": OEXSession.shared()?.currentUser?.username ?? ""]
        return NetworkRequest(
            method: .GET,
            path : "/api/mobile/{version}/users/{username}/course_status_info/{courseID}".oex_format(withParameters: paremeters),
            requiresAuth : true,
            deserializer: .jsonResponse(lastAccessedDeserializer))
    }
    
    public static func setLastVisitedModuleForBlockID(blockID:String, module_id:String) -> NetworkRequest<CourseLastAccessed> {
        let requestParams = UserStatusParameters(courseVisitedModuleId: module_id)
        
        return NetworkRequest(
            method: .PATCH,
            path : "/api/mobile/v0.5/users/{username}/course_status_info/{course_id}".oex_format(withParameters: ["course_id" : blockID, "username": OEXSession.shared()?.currentUser?.username ?? ""]),
            requiresAuth : true,
            body : .jsonBody(requestParams.jsonBody),
            deserializer: .jsonResponse(lastAccessedDeserializer))
    }
    
    private static func setBlockCompletionDeserializer(response : HTTPURLResponse) -> Result<()> {
        guard response.httpStatusCode.is2xx else {
            return Failure()
        }

        return Success(v: ())
    }

    public static func setBlockCompletionRequest(username: String, courseID: String, blockID: String) -> NetworkRequest<()> {
        let body = RequestBody.jsonBody(JSON([
            "username": username,
            "course_key": courseID,
            "blocks" : [ blockID: 1.0]
            ]))

        return NetworkRequest(
            method: .POST,
            path: "/api/completion/v1/completion-batch",
            requiresAuth: true,
            body: body,
            deserializer: .noContent(setBlockCompletionDeserializer)
        )
    }
}
