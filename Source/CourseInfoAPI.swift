//
//  CourseInfoAPI.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 23/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


public struct CourseInfoAPI {
    
    static func handoutsDeserializer(response : NSHTTPURLResponse?, data : NSData?) -> Result<String> {
        return data.toResult(nil).flatMap {data -> Result<String> in
            var error : NSError? = nil
            let result : JSON? = JSON(data: data, options: NSJSONReadingOptions(), error: &error)
            return Result(jsonData: data, error: NSError.oex_courseContentLoadError()) { json in
                json["handouts_html"].string
            }
        }
    }
    
    public static func getHandoutsFromURLString(URLString: String = "/api") -> NetworkRequest<String> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : URLString,
            requiresAuth : true,
            deserializer: handoutsDeserializer)
    }
}