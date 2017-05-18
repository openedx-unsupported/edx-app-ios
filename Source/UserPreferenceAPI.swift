//
//  UserPreferenceAPI.swift
//  edX
//
//  Created by Kevin Kim on 7/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

public class UserPreferenceAPI: NSObject {
    
    private static func preferenceDeserializer(response : HTTPURLResponse, json : JSON) -> Result<UserPreference> {
        return UserPreference(json: json).toResult()
    }
    
    private class func path(username:String) -> String {
        return "/api/user/v1/preferences/{username}".oex_format(withParameters: ["username": username])
    }
    
    class func preferenceRequest(username: String) -> NetworkRequest<UserPreference> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : path(username: username),
            requiresAuth : true,
            deserializer: .jsonResponse(preferenceDeserializer))
    }
    
}
