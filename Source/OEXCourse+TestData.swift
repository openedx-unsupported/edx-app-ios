//
//  OEXCourse+TestData.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public extension OEXCourse {
    
    static func testData(courseHasDiscussions hasDiscussions : Bool = true, accessible : Bool = true, startInfo : OEXCourseStartDisplayInfo? = nil, end: NSDate? = nil, aboutUrl: String? = nil) -> [String : AnyObject] {
        let courseID = NSUUID().UUIDString
        let imagePath = NSBundle.mainBundle().URLForResource("Splash_map", withExtension: "png")
        
        var courseDictionary : [String : AnyObject] = [
            "id" : courseID ?? "someID",
            "subscription_id" : courseID ?? "someSubscriptionID",
            "name" : "A Great Course",
            "course_image" : imagePath!.absoluteString,
            "org" : "edX",
            "courseware_access" : ["has_access" : accessible]
        ]
        if hasDiscussions {
            courseDictionary["discussion_url"] = "http://www.url.com"
        }
        if let end = end {
            courseDictionary["end"] = OEXDateFormatting.serverStringWithDate(end)
        }
        if let startInfo = startInfo {
            courseDictionary = courseDictionary.concat(startInfo.jsonFields)
        }
        if let about = aboutUrl {
            courseDictionary["course_about"] = about
        }
        return courseDictionary
    }
    

    public static func freshCourse(discussionsEnabled hasDiscussions: Bool = true, accessible : Bool = true, startInfo: OEXCourseStartDisplayInfo? = nil, end : NSDate? = nil) -> OEXCourse {
        let courseData = OEXCourse.testData(courseHasDiscussions: hasDiscussions, accessible: accessible, startInfo: startInfo, end: end)
        return OEXCourse(dictionary: courseData)
    }
    
    /// Same as OEXCourse.freshCourse(). Only needed to deal with objc, not having default arguments
    public static func accessibleTestCourse() -> OEXCourse {
        let courseData = OEXCourse.testData(accessible : true)
        return OEXCourse(dictionary: courseData)
    }
    
}