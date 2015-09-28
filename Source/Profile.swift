//
//  Profile.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
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
    }
}

/*
Profile JSON, to be removed once full profile is loaded (MA-1283)
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
*/