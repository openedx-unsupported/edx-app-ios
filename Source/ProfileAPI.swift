//
//  ProfileHelper.swift
//  edX
//
//  Created by Michael Katz on 9/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public class ProfileAPI: NSObject {
    
    private static var currentUserFeed = [String: Feed<UserProfile>]()
    
    private static func profileDeserializer(response : HTTPURLResponse, json : JSON) -> Result<UserProfile> {
        return UserProfile(json: json).toResult()
    }

    private static func imageResponseDeserializer(response : HTTPURLResponse) -> Result<()> {
        return Success(v: ())
    }
    
    private class func path(username:String) -> String {
        return "/api/user/v1/accounts/{username}".oex_format(withParameters: ["username": username])
    }
    
    class func profileRequest(username: String) -> NetworkRequest<UserProfile> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : path(username: username),
            requiresAuth : true,
            deserializer: .jsonResponse(profileDeserializer))
    }
    
    class func getProfile(username: String, networkManager: NetworkManager, handler: @escaping (_ profile: NetworkResult<UserProfile>) -> ()) {
        let request = profileRequest(username: username)
        networkManager.taskForRequest(request, handler: handler)
    }

    class func getProfile(username: String, networkManager: NetworkManager) -> OEXStream<UserProfile> {
        let request = profileRequest(username: username)
        return networkManager.streamForRequest(request)
    }

    class func profileUpdateRequest(profile: UserProfile) -> NetworkRequest<UserProfile> {
        let json = JSON(profile.updateDictionary as AnyObject)
        let request = NetworkRequest(method: HTTPMethod.PATCH,
            path: path(username: profile.username!),
            requiresAuth: true,
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer: .jsonResponse(profileDeserializer))
        return request
    }
    
    class func uploadProfilePhotoRequest(username: String, imageData: NSData) -> NetworkRequest<()> {
        let path = "/api/user/v1/accounts/{username}/image".oex_format(withParameters: ["username" : username])
        return NetworkRequest(method: HTTPMethod.POST,
            path: path,
            requiresAuth: true,
            body: RequestBody.dataBody(data: imageData as Data, contentType: "image/jpeg"),
            headers: ["Content-Disposition":"attachment;filename=filename.jpg"],
            deserializer: .noContent(imageResponseDeserializer))
    }
    
    class func deleteProfilePhotoRequest(username: String) -> NetworkRequest<()> {
        let path = "/api/user/v1/accounts/{username}/image".oex_format(withParameters: ["username" : username])
        return NetworkRequest(method: HTTPMethod.DELETE,
            path: path,
            requiresAuth: true,
            deserializer: .noContent(imageResponseDeserializer))
    }
}
