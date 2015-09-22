//
//  UserProfile.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


class UserProfile {
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

extension UserProfile { //ViewModel
    var image: UIImage? {
        var image = UIImage(named: "avatarPlaceholder")!
        if hasProfileImage && imageURL != nil {
            if let url = NSURL(string: imageURL!), data = NSData(contentsOfURL: url) {
                if let realImage = UIImage(data: data) {
                    image = realImage
                }
            }
        }
        return image
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
        
    }
}

