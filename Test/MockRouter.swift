//
//  MockRouter.swift
//  edX
//
//  Created by Michael Katz on 1/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
@testable import edX

class MockRouter: OEXRouter {
    var logoutCalled = false
    var testType: String = ""

    override func logout() {
        logoutCalled = true
        NotificationCenter.default.post(name:  Notification.Name(rawValue: "MockLogOutCalled"), object: testType)
    }
}
