//
//  OEXSession+Authorization.swift
//  edX
//
//  Created by Akiva Leffert on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXSession : AuthorizationHeaderProvider {
    public var authorizationHeaders : [String:String] {
        if let accessToken = self.token?.accessToken, let tokenType = self.token?.tokenType {
            return ["Authorization" : "\(tokenType) \(accessToken)"]
        }
        else {
            return [:]
        }
    }
}
