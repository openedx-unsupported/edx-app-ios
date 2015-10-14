//
//  ProfileHelper.swift
//  edX
//
//  Created by Michael Katz on 9/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class ProfileAPI: NSObject {
    
    private static func profileDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<UserProfile> {
        return UserProfile(json: json).toResult(NSError.oex_courseContentLoadError())
    }
    
    private class func path(username:String) -> String {
        return "/api/user/v1/accounts/{username}".oex_formatWithParameters(["username": username])
    }
    
    private class func profileRequest(username: String) -> NetworkRequest<UserProfile> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : path(username),
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

    class func profileUpdateRequest(profile: UserProfile) -> NetworkRequest<UserProfile> {
        let json = JSON(profile.updateDictionary)
        let request = NetworkRequest(method: HTTPMethod.PATCH,
            path: path(profile.username!),
            requiresAuth: true,
            body: RequestBody.JSONBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer: .JSONResponse(profileDeserializer))
        return request
    }
    
    class func uploadProfilePhotoRequest(username: String, imageData: NSData) -> NetworkRequest<JSON> {
        let path = "/api/user/v1/accounts/{username}/image".oex_formatWithParameters(["username" : username])
        return NetworkRequest(method: HTTPMethod.POST,
            path: path,
            requiresAuth: true,
            body: RequestBody.DataBody(data: imageData, contentType: "image/jpeg"),
            headers: ["Content-Disposition":"attachment;filename=filename.jpg"],
            deserializer: .JSONResponse({(_, json) in Success(json)}))
    }
}
