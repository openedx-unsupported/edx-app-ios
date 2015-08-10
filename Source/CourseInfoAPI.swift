//
//  CourseInfoAPI.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 23/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


public struct CourseInfoAPI {
    
    static func handoutsDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<String> {
        return json["handouts_html"].string.toResult(NSError.oex_courseContentLoadError())
    }
    
    public static func getHandoutsFromURLString(URLString: String = "/api") -> NetworkRequest<String> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : URLString,
            requiresAuth : true,
            deserializer: .JSONResponse(handoutsDeserializer)
        )
    }
}