//
//  UserCourseEnrollment.swift
//  edX
//
//  Created by Michael Katz on 11/12/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore

//TODO: remove NSObject when done with @objc
public class UserCourseEnrollment : NSObject {
    let created: String?
    let mode: String?
    let isActive: Bool
    let course: OEXCourse

    /** Url if the user has completed a certificate */
    let certificateUrl: String?

    init?(dictionary: [String: Any]) {
        created = dictionary["created"] as? String
        mode = dictionary["mode"] as? String
        isActive = (dictionary["is_active"] as? NSNumber)?.boolValue ?? false


        if let certificatesInfo = dictionary["certificate"] as? [String: Any] {
            certificateUrl = certificatesInfo["url"] as? String
        } else {
            certificateUrl = nil
        }
        
        if let dictCourse = dictionary["course"] as? [NSObject: AnyObject] {
            course = OEXCourse(dictionary:dictCourse)
        } else {
            course = OEXCourse()
            super.init()
            return nil
        }
        
        super.init()
    }
    
    init(course: OEXCourse, created: String? = nil, mode: String? = nil, isActive: Bool = true, certificateURL: String? = nil) {
        self.created = created
        self.mode = mode
        self.course = course
        self.isActive = isActive
        self.certificateUrl = certificateURL
    }
    
    convenience init?(json: JSON) {
        guard let dict = json.dictionaryObject else {
            self.init(dictionary:[:])
            return nil
        }
        self.init(dictionary: dict)
    }
}
