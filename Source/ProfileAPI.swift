//
//  ProfileHelper.swift
//  edX
//
//  Created by Michael Katz on 9/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class ProfileAPI: NSObject {
    
    private static var currentUserFeed = [String: Feed<UserProfile>]()
    
    private static func profileDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<UserProfile> {
        let profile = UserProfile(json: json)
        if let profile = profile, username = profile.username where username == OEXSession.sharedSession()?.currentUser?.username {
            dispatch_async(dispatch_get_main_queue()) {
                currentUserFeed[username]?.backing.send(.Success(Box(profile)))
            }
        }
        return profile.toResult(NSError.oex_unknownError())
    }

    private static func imageResponseDeserializer(response : NSHTTPURLResponse) -> Result<()> {
        return Success()
    }
    
    private class func path(username:String) -> String {
        return "/api/user/v1/accounts/{username}".oex_formatWithParameters(["username": username])
    }
    
    class func profileRequest(username: String) -> NetworkRequest<UserProfile> {
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
    
    public class func getProfileFeed(username: String, networkManager: NetworkManager) -> Feed<UserProfile> {
        //if the feed is for the current user, return the singleton version of it. This way when it is updated in one spot, all areas will inherit the change. Rather than needing to constantly reload
        let currentUsername = OEXSession.sharedSession()?.currentUser?.username
        guard currentUsername != username else {
            if let currentFeed = currentUserFeed[username] {
                return currentFeed
            }
            currentUserFeed.removeAll()
            let request = profileRequest(username)
            let feed = Feed(request: request, manager: networkManager)
            currentUserFeed[username] = feed
            return feed
        }

        let request = profileRequest(username)
        return Feed(request: request, manager: networkManager)
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
    
    class func uploadProfilePhotoRequest(username: String, imageData: NSData) -> NetworkRequest<()> {
        let path = "/api/user/v1/accounts/{username}/image".oex_formatWithParameters(["username" : username])
        return NetworkRequest(method: HTTPMethod.POST,
            path: path,
            requiresAuth: true,
            body: RequestBody.DataBody(data: imageData, contentType: "image/jpeg"),
            headers: ["Content-Disposition":"attachment;filename=filename.jpg"],
            deserializer: .NoContent(imageResponseDeserializer))
    }
    
    class func deleteProfilePhotoRequest(username: String) -> NetworkRequest<()> {
        let path = "/api/user/v1/accounts/{username}/image".oex_formatWithParameters(["username" : username])
        return NetworkRequest(method: HTTPMethod.DELETE,
            path: path,
            requiresAuth: true,
            deserializer: .NoContent(imageResponseDeserializer))
    }
}
