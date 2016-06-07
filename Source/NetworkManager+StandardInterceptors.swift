//
//  NetworkManager+StandardInterceptors.swift
//  edX
//
//  Created by Akiva Leffert on 3/9/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

import edXCore

extension NetworkManager {
    public func addStandardInterceptors() {
        let deprecatedVersionInterceptor = { response, json in
            NetworkManager.deprecatedVersionInterceptor(response, json: json)
        }
        addJSONInterceptor(NetworkManager.courseAccessInterceptor)
        addJSONInterceptor(deprecatedVersionInterceptor)
    }
    
    static func courseAccessInterceptor(response: NSHTTPURLResponse, json: JSON) -> Result<JSON> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode) where statusCode.is4xx else {
            return Success(json)
        }
        
        if json["has_access"].bool == false {
            let access = OEXCoursewareAccess(dictionary : json.dictionaryObject)
            return Failure(OEXCoursewareAccessError(coursewareAccess: access, displayInfo: nil))
        }
        return Success(json)
    }
    
    static func deprecatedVersionInterceptor(response: NSHTTPURLResponse, json: JSON) -> Result<JSON> {
        let versionController = VersionUpgradeInfoController.sharedController
        versionController.populateFromHeaders(httpResponseHeaders: response.allHeaderFields)
        return Success(json)
    }
}
