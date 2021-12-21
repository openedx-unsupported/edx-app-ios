//
//  UserCourseEnrollment.swift
//  edX
//
//  Created by Michael Katz on 11/12/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public enum EnrollmentMode: String {
    case audit = "audit"
    case verified = "verified"
    case honor = "honor"
    case noIDProfessional = "no-id-professional"
    case professional = "professional"
    case credit = "credit"
    case masters = "masters"
    case none = "none"
}

//TODO: remove NSObject when done with @objc
public class UserCourseEnrollment : NSObject {
    let created: String?
    let mode: String?
    @objc let isActive: Bool
    @objc let course: OEXCourse
    
    var type: EnrollmentMode
    
    /** Url if the user has completed a certificate */
    let certificateUrl: String?

    @objc init?(dictionary: [String : Any]) {
        created = dictionary["created"] as? String
        mode = dictionary["mode"] as? String
        isActive = (dictionary["is_active"] as? NSNumber)?.boolValue ?? false
        if let mode = mode {
            type = EnrollmentMode(rawValue: mode) ?? .none
        } else {
            type = .none
        }
        
        if let certificatesInfo = dictionary["certificate"] as? [String: Any] {
            certificateUrl = certificatesInfo["url"] as? String
        } else {
            certificateUrl = nil
        }
        
        if let dictCourse = dictionary["course"] as? [NSObject: AnyObject] {
            course = OEXCourse(dictionary: dictCourse, auditExpiryDate: dictionary["audit_access_expires"] as? String)
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
        if let mode = mode {
            self.type = EnrollmentMode(rawValue: mode) ?? .none
        } else {
            self.type = .none
        }
    }
    
    convenience init?(json: JSON) {
        guard let dict = json.dictionaryObject else {
            self.init(dictionary:[:])
            return nil
        }
        self.init(dictionary: dict)
    }
}
