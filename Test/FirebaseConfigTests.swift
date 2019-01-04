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
        XCTAssertEqual(config.firebaseConfig.apiKey, "")
        XCTAssertEqual(config.firebaseConfig.clientID, "")
        XCTAssertEqual(config.firebaseConfig.gcmSenderID, "")
        XCTAssertEqual(config.firebaseConfig.googleAppID, "")
        
    }

    func testEmptyFirebaseConfig() {
        let config = OEXConfig(dictionary:["FIREBASE":[:]])
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertEqual(config.firebaseConfig.apiKey, "")
        XCTAssertEqual(config.firebaseConfig.clientID, "")
        XCTAssertEqual(config.firebaseConfig.gcmSenderID, "")
        XCTAssertEqual(config.firebaseConfig.googleAppID, "")
    }

    func testFirebaseConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "ANALYTICS_ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "GCM_SENDER_ID": "608417025925",
                "API_KEY": "Zhk6QiW7EbQW0WxJ5mzzZV9hDN8xEo",
                "CLIENT_ID": "6i9smf15pi4baevepjrsscmbht9bg2ah.apps.googleusercontent.com",
                "GOOGLE_APP_ID": "608417025925:ios:c04089bb49270266"
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.analyticsEnabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertEqual(config.firebaseConfig.apiKey, "Zhk6QiW7EbQW0WxJ5mzzZV9hDN8xEo")
        XCTAssertEqual(config.firebaseConfig.clientID, "6i9smf15pi4baevepjrsscmbht9bg2ah.apps.googleusercontent.com")
        XCTAssertEqual(config.firebaseConfig.gcmSenderID, "608417025925")
        XCTAssertEqual(config.firebaseConfig.googleAppID, "608417025925:ios:c04089bb49270266")
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
