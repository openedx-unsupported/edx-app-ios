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
    var linkedin: String? = nil
    var mail:String? = nil
    
    
    @objc init?(params: [String: Any]) {
        facebook = params["facebook"] as? String
        twitter = params["twitter"] as? String
        super.init()
    }
    
    @objc convenience init?(utmParams: [String: Any]) {
        self.init(params: utmParams)
        linkedin = utmParams["linkedin"] as? String
        mail = utmParams["email"] as? String
    }
    
}
