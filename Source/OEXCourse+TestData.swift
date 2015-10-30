//
//  OEXCourse+TestData.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public extension OEXCourse {
    
    static func testData(courseHasDiscussions hasDiscussions : Bool = true, isAccessible : Bool = true) -> [String : AnyObject] {
        let courseID = NSUUID().UUIDString
        let imagePath = NSBundle.mainBundle().URLForResource("Splash_map", withExtension: "png")
        
        var courseDictionary : [String : AnyObject] = [
            "id" : courseID ?? "someID",
            "subscription_id" : courseID ?? "someSubscriptionID",
            "name" : "A Great Course",
            "course_image" : imagePath!.absoluteString,
            "org" : "edX",
            "courseware_access" : ["has_access" : isAccessible]
        ]
        if hasDiscussions {
            courseDictionary["discussion_url"] = "http://www.url.com"
        }
        return courseDictionary
    }
    

    public static func freshCourse(withDiscussionsEnabled hasDiscussions: Bool = true, accessible : Bool = true) -> OEXCourse {
       let courseData = OEXCourse.testData(courseHasDiscussions: hasDiscussions, isAccessible: accessible)
        return OEXCourse(dictionary: courseData)
        
    }
}