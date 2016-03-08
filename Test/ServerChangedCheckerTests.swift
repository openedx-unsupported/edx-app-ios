//
//  ServerChangedCheckerTests.swift
//  edX
//
//  Created by Akiva Leffert on 3/3/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX

class ServerChangedCheckerTests: XCTestCase {

    func testNoPreviousServerNoEffect() {
        let defaultsRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let checker = ServerChangedChecker()
        let config = OEXConfig(dictionary: ["API_HOST_URL": "http://test.com"])
        checker.logoutIfServerChanged(config: config) {
            XCTFail()
        }
        defaultsRemover.remove()
    }

    func testServerChangedTriggersLogout() {
        let defaultsRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let checker = ServerChangedChecker()
        let config = OEXConfig(dictionary: ["API_HOST_URL": "http://test.com"])
        checker.logoutIfServerChanged(config: config) {}

        let newConfig = OEXConfig(dictionary: ["API_HOST_URL": "http://new-server.com"])
        var loggedOut = false
        checker.logoutIfServerChanged(config: newConfig) {
            loggedOut = true
        }
        XCTAssertTrue(loggedOut)
        defaultsRemover.remove()
    }

    func testSameServerNoEffect() {
        let defaultsRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let checker = ServerChangedChecker()
        let config = OEXConfig(dictionary: ["API_HOST_URL": "http://test.com"])
        checker.logoutIfServerChanged(config: config) {}
        checker.logoutIfServerChanged(config: config) {
            XCTFail()
        }
        defaultsRemover.remove()
    }
}
