//
//  UserCourseEnrollement.swift
//  edX
//
//  Created by Michael Katz on 11/12/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

//TODO: remove NSObject when done with @objc
class UserCourseEnrollment : NSObject {
    let created: String?
    let mode: String?
    let isActive: Bool
    let course: OEXCourse?

    /** Url if the user has completed a certificate */
    let certificateUrl: String?

    init(dictionary: [NSObject: AnyObject]) {
        created = dictionary["created"] as? String
        mode = dictionary["mode"] as? String
        isActive = (dictionary["is_active"] as? NSNumber)?.boolValue ?? false

        if let dictCourse = dictionary["course"] as? [NSObject: AnyObject] {
            course = OEXCourse(dictionary:dictCourse)
        } else {
            course = nil
        }


        if let certificatesInfo = dictionary["certificate"] as? [NSObject: AnyObject] {
            certificateUrl = certificatesInfo["url"] as? String
        } else {
            certificateUrl = nil
        }
        super.init()
    }
}