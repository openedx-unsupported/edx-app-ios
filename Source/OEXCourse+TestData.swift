//
//  OEXCourse+TestData.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public extension OEXCourse {

    public static func freshCourse(withDiscussionsEnabled enabled: Bool = true) -> OEXCourse {
        let courseID = NSUUID().UUIDString
        let imagePath = NSBundle.mainBundle().URLForResource("Splash_map", withExtension: "png")
        
        var courseDictionary = [
            "id" : courseID ?? "someID",
            "subscription_id" : courseID ?? "someSubscriptionID",
            "name" : "A Great Course",
            "course_image" : imagePath!.absoluteString,
            "org" : "edX",
        ]
        if enabled {
            courseDictionary["discussion_url"] = "http://www.url.com"
        }
        
        return OEXCourse(dictionary: courseDictionary)
        
    }

}