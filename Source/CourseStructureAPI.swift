//
//  ServerAPI.swift
//  edX
//
//  Created by Akiva Leffert on 5/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import edXCore

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
                "requested_fields" : JSON(fields.joined(separator: ",") as AnyObject),
                "block_counts" : JSON(blockCount.joined(separator: ",") as AnyObject),
                "student_view_data" : JSON(studentViewData.map({ $0.rawValue }).joined(separator: ",")),
                "depth": "all",
                "nav_depth": 3,
                "course_id": JSON(courseID)
            ]
            
            if let username = username {
                result["username"] = JSON(username)
            }
            
            return result
            
        }
    }
    
    static func deserializer(response : HTTPURLResponse, json : JSON) -> Result<CourseOutline> {
        return CourseOutline(json: json).toResult(NSError.oex_courseContentLoadError())
    }
    
    static func requestWithCourseID(courseID : String, username : String?, environment: RouterEnvironment?) -> NetworkRequest<CourseOutline> {
        let parameters = Parameters(
            courseID: courseID,
            username: username,
            fields : [
                CourseOutline.Fields.Graded.rawValue,
                CourseOutline.Fields.StudentViewMultiDevice.rawValue,
                CourseOutline.Fields.Format.rawValue,
                CourseOutline.Fields.Graded.rawValue,
                CourseOutline.Fields.isCompleted.rawValue,
                CourseOutline.Fields.ContainsGatedContent.rawValue,
                CourseOutline.Fields.ShowGatedSections.rawValue,
                CourseOutline.Fields.SpecialExamInfo.rawValue
            ],
            blockCount : [CourseBlock.Category.Video.rawValue],
            studentViewData : [CourseBlock.Category.Video, CourseBlock.Category.Discussion]
        )
        
        let apiVersion = environment?.config.apiUrlVersionConfig.blocks ?? APIURLDefaultVersion.blocks.rawValue
        
        return NetworkRequest(
            method : .GET,
            path : "/api/courses/{api_version}/blocks/".oex_format(withParameters: ["api_version" : apiVersion]),
            requiresAuth : true,
            query : parameters.query,
            deserializer : .jsonResponse(deserializer)
        )
    }
}
