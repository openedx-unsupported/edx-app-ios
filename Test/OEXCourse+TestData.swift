
//
//  OEXCourse+TestData.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public extension OEXCourse {
    
    public static func testData(
        courseHasDiscussions hasDiscussions : Bool = true,
        hasHandoutsUrl : Bool = true,
        accessible : Bool = true,
        overview: String? = nil,
        shortDescription : String? = nil,
        effort: String? = nil,
        mediaInfo: [String:CourseMediaInfo] = [:],
        startInfo : OEXCourseStartDisplayInfo? = nil,
        end: NSDate? = nil,
        aboutUrl: String? = nil) -> [String : AnyObject]
    {
        let courseID = NSUUID().UUIDString
        let imagePath = NSBundle.mainBundle().URLForResource("placeholderCourseCardImage", withExtension: "png")
        
        var courseDictionary : [String : AnyObject] = [
            "id" : courseID ?? "someID",
            "subscription_id" : courseID ?? "someSubscriptionID",
            "name" : "A Great Course",
            "course_image" : imagePath!.absoluteString ?? imagePath!.URLString,
            "org" : "edX",
            "courseware_access" : ["has_access" : accessible]
        ]
        if let overview = overview {
            courseDictionary["overview"] = overview
        }
        if hasDiscussions {
            courseDictionary["discussion_url"] = "http://www.url.com"
        }
        
        if hasHandoutsUrl {
            courseDictionary["course_handouts"] = "http://www.url.com"
        }
        
        var unparsedMediaInfos : [String:AnyObject] = [:]
        for (name, info) in mediaInfo {
            unparsedMediaInfos[name] = info.dictionary
        }
        courseDictionary["media"] = unparsedMediaInfos
        
        if let description = shortDescription {
            courseDictionary["short_description"] = description
        }
        if let effort = effort {
            courseDictionary["effort"] = effort
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
    

    public static func freshCourse(
        discussionsEnabled hasDiscussions: Bool = true,
                           hasHandoutsUrl: Bool = true,
        accessible : Bool = true,
        shortDescription: String? = nil,
        overview: String? = nil,
        effort: String? = nil,
        mediaInfo: [String:CourseMediaInfo] = [:],
        startInfo: OEXCourseStartDisplayInfo? = nil,
        end : NSDate? = nil
        ) -> OEXCourse
    {
        let courseData = OEXCourse.testData(
            courseHasDiscussions: hasDiscussions,
            hasHandoutsUrl: hasHandoutsUrl,
            accessible: accessible,
            shortDescription: shortDescription,
            overview: overview,
            effort:effort,
            mediaInfo: mediaInfo,
            startInfo: startInfo,
            end: end)
        return OEXCourse(dictionary: courseData)
    }
    
    /// Same as OEXCourse.freshCourse(). Only needed to deal with objc, not having default arguments
    public static func accessibleTestCourse() -> OEXCourse {
        let courseData = OEXCourse.testData(accessible : true)
        return OEXCourse(dictionary: courseData)
    }
    
}
