//
//  CourseShareUtmParameter.swift
//  edX
//
//  Created by Salman on 15/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

@objc class CourseShareUtmParameter: NSObject {

    let facebook: String?
    let twitter: String?
    
    init?(dictionary: [String: Any]) {
        facebook = dictionary["facebook"] as? String
        twitter = dictionary["twitter"] as? String
        super.init()
    }
    
}
