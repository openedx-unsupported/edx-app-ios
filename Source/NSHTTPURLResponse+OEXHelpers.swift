//
//  NSHTTPURLResponse+OEXHelpers.swift
//  edX
//
//  Created by Michael Katz on 10/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension NSHTTPURLResponse {
    func hasErrorResponseCode() -> Bool {
        return statusCode >= 400
    }
    
    var httpStatusCode : OEXHTTPStatusCode {
        return OEXHTTPStatusCode(rawValue: self.statusCode) ?? .Code500InternalServerError
    }
}