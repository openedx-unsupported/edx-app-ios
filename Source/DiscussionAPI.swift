//
//  DiscussionAPI.swift
//  edX
//
//  Created by Tang, Jeff on 6/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


public class DiscussionAPI {
    static func createNewThread(json: JSON) -> NetworkRequest<NSObject> {
        return NetworkRequest(
            method : HTTPMethod.POST,
            path : "/api/discussion/v1/threads/",
            requiresAuth : true,
            body: RequestBody.JSONBody(json),
            deserializer : {(response, data) -> Result<NSObject> in
                var dataString = NSString(data: data!, encoding:NSUTF8StringEncoding)
                #if DEBUG
                    println("\(response), \(dataString)")
                #endif
                
                return Failure(nil)
        })
    }
    
//    static func getThreads(courseID: String) -> NetworkRequest<NSObject> {
//        return NetworkRequest(

}