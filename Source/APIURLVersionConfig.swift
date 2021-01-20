//
//  APIURLVersionConfig.swift
//  edX
//
//  Created by Salman on 08/07/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import UIKit

enum APIURLDefaultVersion: String {
    case blocks, registration = "v1"
    case resumeCourse = "v0.5"
}

fileprivate enum APIURLVersionKeys: String, RawStringExtractable {
    case blocks = "BLOCKS"
    case registration = "REGISTRATION"
    case resumeCourse = "RESUME_COURSE"
}

@objc class APIURLVersionConfig: NSObject {

    let blocks: String
    @objc let registration: String
    let resumeCourse: String
    
    init(dictionary: [String: AnyObject]) {
        blocks = dictionary[APIURLVersionKeys.blocks] as? String ?? APIURLDefaultVersion.blocks.rawValue
        registration = dictionary[APIURLVersionKeys.registration] as? String ?? APIURLDefaultVersion.registration.rawValue
        resumeCourse = dictionary[APIURLVersionKeys.resumeCourse] as? String ?? APIURLDefaultVersion.resumeCourse.rawValue
        super.init()
    }
}

private let key = "API_URL_VERSION"
extension OEXConfig {
    @objc var apiUrlVersionConfig: APIURLVersionConfig {
        return APIURLVersionConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
