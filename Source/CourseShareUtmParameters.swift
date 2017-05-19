//
//  CourseShareUtmParameters.swift
//  edX
//
//  Created by Salman on 19/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

@objc class CourseShareUtmParameters: NSObject {

    let facebook: String?
    let twitter: String?
    
    init?(Params: [String: Any]) {
        facebook = Params["facebook"] as? String
        twitter = Params["twitter"] as? String
        super.init()
    }
}
