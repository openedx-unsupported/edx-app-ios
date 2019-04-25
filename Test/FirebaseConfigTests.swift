//
//  FirebaseConfigTests.swift
//  edXTests
//
//  Created by Saeed Bashir on 8/28/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

@testable import edX

class FirebaseConfigTests: XCTestCase {

    func testNoFirebaseConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
        
    }

    func testEmptyFirebaseConfig() {
        let config = OEXConfig(dictionary:["FIREBASE":[:]])
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }

    func testFirebaseConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "ANALYTICS_ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.analyticsEnabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
    }

    func testFirebaseDisableConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": false,
                "ANALYTICS_ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }

    func testFirebaseDisableAnalytics() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "ANALYTICS_ENABLED": false,
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }

    func testFirebaseDisableCloudMessaging() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
    }
}
