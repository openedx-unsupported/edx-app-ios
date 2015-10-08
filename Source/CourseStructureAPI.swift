//
//  ServerAPI.swift
//  edX
//
//  Created by Akiva Leffert on 5/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public struct CourseOutlineAPI {
    struct Parameters {
        let courseID: String
        let username : String?
        let fields : [String]
        let blockCount : [String]
        let studentViewData : [CourseBlock.Category]
        
        var query : [String:JSON] {
            var result =
            [
                "requested_fields" : JSON(fields.joinWithSeparator(",")),
                "block_counts" : JSON(blockCount.joinWithSeparator(",")),
                "student_view_data" : JSON(studentViewData.map({ $0.rawValue }).joinWithSeparator(",")),
                "depth": "all",
                "nav_depth": 3,
                "course_id": JSON(courseID)
            ]
            
            if let username = username {
                result["user"] = JSON(username)
            }
            
            return result
            
        }
    }
    
    static func deserializer(response : NSHTTPURLResponse, json : JSON) -> Result<CourseOutline> {
        return CourseOutline(json: json).toResult(NSError.oex_courseContentLoadError())
    }
    
    public static func requestWithCourseID(courseID : String, username : String?) -> NetworkRequest<CourseOutline> {
        let parameters = Parameters(
            courseID: courseID,
            username: username,
            fields : ["graded", "student_view_multi_device", "format"],
            blockCount : [CourseBlock.Category.Video.rawValue],
            studentViewData : [CourseBlock.Category.Video]
        )
        return NetworkRequest(
            method : .GET,
            path : "/api/courses/v1/blocks/",
            requiresAuth : true,
            query : parameters.query,
            deserializer : .JSONResponse(deserializer)
        )
    }
}
