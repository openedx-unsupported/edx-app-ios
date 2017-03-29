//
//  NSHTTPURLResponse+OEXHelpers.swift
//  edX
//
//  Created by Michael Katz on 10/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    public func hasErrorResponseCode() -> Bool {
        return statusCode >= 400
    }
    
    public var httpStatusCode : OEXHTTPStatusCode {
        return OEXHTTPStatusCode(rawValue: self.statusCode) ?? .code500InternalServerError
    }
}
