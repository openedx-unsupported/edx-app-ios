//
//  ServerAPI.swift
//  edX
//
//  Created by Akiva Leffert on 5/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public struct CourseOutlineAPI {
    public struct Parameters {
        let children : Bool
        let blockCount : [String]
        let blockData : [String:AnyObject]
        
        var query : [String:JSON] {
            return [
                    "children" : JSON(children),
                    "blockCount" : JSON(blockCount),
                    "blockData" : JSON(blockData)
            ]
        }
    }
    
    static func fromData(response : NSHTTPURLResponse?, data : NSData?) -> Result<CourseOutline> {
        return data.toResult(nil).flatMap {data -> Result<AnyObject> in
            var error : NSError? = nil
            let result : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &error)
            return result.toResult(error)
        }.flatMap {json in
            return CourseOutline(json: JSON(json)).toResult(NSError.oex_unknownError())
        }
    }
    
    static func requestWithCourseID(courseID : String) -> NetworkRequest<CourseOutline> {
        let parameters = Parameters(
            children : false,
            blockCount : ["video"],
            blockData : ["video" : ["profile" : ["mobile_high", "mobile_low"]]]
        )
        return NetworkRequest(
            method : .GET,
            path : "api/course_structure/v0/courses/{courseID}/blocks+navigation/".oex_formatWithParameters(["courseID" : courseID]),
            requiresAuth : true,
            query : parameters.query,
            deserializer : fromData
        )
    }
}
