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
    public func addStandardInterceptors(router:OEXRouter) {
        let invalidAccessInterceptor = {[weak router] response, json in
            NetworkManager.invalidAccessInterceptor(router, response: response, json: json)
        }
        
        let deprecatedVersionInterceptor = {[weak router] response, json in
            NetworkManager.deprecatedVersionInterceptor(router, response: response, json: json)
        }
        
        addJSONInterceptor(NetworkManager.courseAccessInterceptor)
        addJSONInterceptor(invalidAccessInterceptor)
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

    static func invalidAccessInterceptor(router: OEXRouter?, response: NSHTTPURLResponse, json: JSON) -> Result<JSON> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
            error = NSError(json: json, code: response.statusCode)
            where statusCode == .Code401Unauthorised else
        {
            return Success(json)
        }
        dispatch_async(dispatch_get_main_queue()) {
            if error.isAPIError(.OAuth2Expired) {
                //TODO: In Phase 2 actually refresh the token: MA-1772
                router?.logout()
            } else {
                router?.logout()
            }
        }
        return Failure(error)
    }
    
    static func deprecatedVersionInterceptor(router: OEXRouter?, response: NSHTTPURLResponse, json: JSON) -> Result<JSON> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
            error = NSError(json: json, code: response.statusCode)
            where statusCode == .Code426UpgradeRequired else
        {
            let versionController = VersionUpgradeInfoController.sharedController
            versionController.populateFromHeaders(httpResponseHeaders: response.allHeaderFields)
            return Success(json)
        }
        return Failure(error)
    }
}
