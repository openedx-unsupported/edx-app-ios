//
//  ProfileHelper.swift
//  edX
//
//  Created by Michael Katz on 9/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class Profile {
    let hasProfileImage:Bool
    let imageURL:String?
    
    init?(json: JSON) {
        if let profileImage = json["profile_image"].dictionary {
            hasProfileImage = profileImage["has_image"]?.bool ?? false
            if hasProfileImage {
                imageURL = profileImage["image_url_full"]?.string
            } else {
                imageURL = nil
            }
        } else {
            hasProfileImage = false
            imageURL = nil
        }
    }
}

extension Profile { //ViewModel
    var image: RemoteImage {
        
        let url = hasProfileImage && imageURL != nil ? imageURL! : ""
        return RemoteImageImpl(url: url, placeholder: UIImage(named: "avatarPlaceholder"))
//        
//        var image = UIImage(named: "avatarPlaceholder")!
//        if hasProfileImage && imageURL != nil {
//            if let url = NSURL(string: imageURL!), data = NSData(contentsOfURL: url) {
//                if let realImage = UIImage(data: data) {
//                    image = realImage
//                }
//            }
//        }
//        return image
//        //            var image = UIImage(named: "avatarPlaceholder")!
//        //            if let profile = result.data {
//        //                if profile.hasProfileImage && profile.imageURL != nil {
//        //                    //TODO: cache
//        //                    if let url = NSURL(string: profile.imageURL!), data = NSData(contentsOfURL: url) {
//        //                        if let realImage = UIImage(data: data) {
//        //                            image = realImage
//        //                        }
//        //                    }
//        //                }
//        //            }
//
    }
}


class ProfileHelper: NSObject {
    
    private static func profileDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<Profile> {
        return Profile(json: json).toResult(NSError.oex_courseContentLoadError())
    }

    
//    API for user profile data: GET /api/user/v1/accounts/:username
//    API for user profile image: GET /api/user/v1/accounts/:username/image
 /*
    {
    "username": "staff",
    "profile_image": {
    "image_url_full": "https://mobile-dev.sandbox.edx.org/static/images/default-theme/default-profile_500.de2c6854f1eb.png",
    "image_url_large": "https://mobile-dev.sandbox.edx.org/static/images/default-theme/default-profile_120.33ad4f755071.png",
    "image_url_medium": "https://mobile-dev.sandbox.edx.org/static/images/default-theme/default-profile_50.5fb006f96a15.png",
    "image_url_small": "https://mobile-dev.sandbox.edx.org/static/images/default-theme/default-profile_30.ae6a9ca9b390.png",
    "has_image": false
    }
    }
    */
    
    class func getProfile(username: String, handler: (profile: NetworkResult<Profile>) -> ()) {
        let request = NetworkRequest(
            method: HTTPMethod.GET,
            path : "/api/user/v1/accounts/{username}".oex_formatWithParameters(["username":OEXSession.sharedSession()?.currentUser?.username ?? ""]),
            requiresAuth : true,
            deserializer: .JSONResponse(profileDeserializer))
        
        OEXRouter.sharedRouter().environment.networkManager.taskForRequest(request, handler: handler)
    }
    
    
//    class func getProfileImage(profile: Profile, completion: (image: UIImage)->()) {
//        let
//        
//        
//        let request = NetworkRequest(
//            method: HTTPMethod.GET,
//            path : "/api/user/v1/accounts/{username}".oex_formatWithParameters(["username":OEXSession.sharedSession()?.currentUser?.username ?? ""]),
//            requiresAuth : true,
//            deserializer: .JSONResponse(profileDeserializer))
//
//        OEXRouter.sharedRouter().environment.networkManager.taskForRequest(request) { result in
//            var image = UIImage(named: "avatarPlaceholder")!
//            if let profile = result.data {
//                if profile.hasProfileImage && profile.imageURL != nil {
//                    //TODO: cache
//                    if let url = NSURL(string: profile.imageURL!), data = NSData(contentsOfURL: url) {
//                        if let realImage = UIImage(data: data) {
//                            image = realImage
//                        }
//                    }
//                }
//            }
//            dispatch_async(dispatch_get_main_queue()) { completion(image: image) }
//        }
//    }
//    
//    class func parseRequest(result: Result<UIImage?>) {}
}

/*
(lldb) po json
{
"email" : "staff@example.com",
"year_of_birth" : 1990,
"language_proficiencies" : [

],
"mailing_address" : "",
"is_active" : true,
"level_of_education" : "a",
"bio" : null,
"goals" : "",
"profile_image" : {
"image_url_small" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_30.ae6a9ca9b390.png",
"image_url_full" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_500.de2c6854f1eb.png",
"image_url_medium" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_50.5fb006f96a15.png",
"image_url_large" : "https:\/\/mobile-stable.sandbox.edx.org\/static\/images\/default-theme\/default-profile_120.33ad4f755071.png",
"has_image" : false
},
"date_joined" : "2015-07-16T09:46:38Z",
"username" : "Staff123",
"requires_parental_consent" : false,
"country" : null,
"name" : "Staff",
"gender" : "m"
}

(lldb)*/