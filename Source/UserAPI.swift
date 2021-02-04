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

    private static func resumeCourseDeserializer(response : HTTPURLResponse, json : JSON) -> Result<ResumeCourseItem> {
        return ResumeCourseItem(json: json).toResult()
    }
    
    public static func requestResumeCourseBlock(for courseID: String) -> NetworkRequest<ResumeCourseItem> {
        let paremeters = [
            "courseID": courseID,
            "username": OEXSession.shared()?.currentUser?.username ?? ""
        ]
        return NetworkRequest(
            method: .GET,
            path : "/api/mobile/v1/users/{username}/course_status_info/{courseID}".oex_format(withParameters: paremeters),
            requiresAuth : true,
            deserializer: .jsonResponse(resumeCourseDeserializer))
    }
}
