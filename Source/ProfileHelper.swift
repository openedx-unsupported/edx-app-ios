//
//  ProfileHelper.swift
//  edX
//
//  Created by Michael Katz on 9/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class ProfileHelper: NSObject {
    
    private static func profileDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<UserProfile> {
        return UserProfile(json: json).toResult(NSError.oex_courseContentLoadError())
    }
    
    
    private class func profileRequest(username: String) -> NetworkRequest<UserProfile> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : "/api/user/v1/accounts/{username}".oex_formatWithParameters(["username": username]),
            requiresAuth : true,
            deserializer: .JSONResponse(profileDeserializer))
    }
    
    class func getProfile(username: String, networkManager: NetworkManager, handler: (profile: NetworkResult<UserProfile>) -> ()) {
        let request = profileRequest(username)
        networkManager.taskForRequest(request, handler: handler)
    }

    class func getProfile(username: String, networkManager: NetworkManager) -> Stream<UserProfile> {
        let request = profileRequest(username)
        return networkManager.streamForRequest(request)
    }

    
}
