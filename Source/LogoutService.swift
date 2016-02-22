//
//  LogoutService.swift
//  edX
//
//  Created by Michael Katz on 1/25/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

/** Helper to encapsulate logout logic */
class LogoutService {
    class func logout() {
        OEXRouter.sharedRouter().logout()
    }
}