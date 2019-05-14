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
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : "APebSdWSu456EDkUk0imSGqetnOznbZv22QRiq1",
                "CLIENT_ID" : "302611111829-s11900000000tdhcbj9876548888qur3.apps.googleusercontent.com",
                "GOOGLE_APP_ID" : "3:902600000000:ios:c00089xx00000266",
                "GCM_SENDER_ID" : "303600005829"
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
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : "APebSdWSu456EDkUk0imSGqetnOznbZv22QRiq1",
                "CLIENT_ID" : "302611111829-s11900000000tdhcbj9876548888qur3.apps.googleusercontent.com",
                "GOOGLE_APP_ID" : "3:902600000000:ios:c00089xx00000266",
                "GCM_SENDER_ID" : "303600005829"
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
                "API_KEY" : "APebSdWSu456EDkUk0imSGqetnOznbZv22QRiq1",
                "CLIENT_ID" : "302611111829-s11900000000tdhcbj9876548888qur3.apps.googleusercontent.com",
                "GOOGLE_APP_ID" : "3:902600000000:ios:c00089xx00000266",
                "GCM_SENDER_ID" : "303600005829"
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
                "ANALYTICS_ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": false,
                "API_KEY" : "APebSdWSu456EDkUk0imSGqetnOznbZv22QRiq1",
                "CLIENT_ID" : "302611111829-s11900000000tdhcbj9876548888qur3.apps.googleusercontent.com",
                "GOOGLE_APP_ID" : "3:902600000000:ios:c00089xx00000266",
                "GCM_SENDER_ID" : "303600005829"
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }
    
    func testFirebaseRequiredKeysAvailable() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "ANALYTICS_ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : "APebSdWSu456EDkUk0imSGqetnOznbZv22QRiq1",
                "CLIENT_ID" : "302611111829-s11900000000tdhcbj9876548888qur3.apps.googleusercontent.com",
                "GOOGLE_APP_ID" : "3:902600000000:ios:c00089xx00000266",
                "GCM_SENDER_ID" : "303600005829"
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.analyticsEnabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
    }
    
    func testFirebaseRequiredKeysNotAvailable() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "ANALYTICS_ENABLED": false,
                "CLOUD_MESSAGING_ENABLED": false,
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }
    
    func testFirebaseRequiredKeyMissing() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "ANALYTICS_ENABLED": false,
                "CLOUD_MESSAGING_ENABLED": true,
                "CLIENT_ID" : "302611111829-s11900000000tdhcbj9876548888qur3.apps.googleusercontent.com",
                "GOOGLE_APP_ID" : "3:902600000000:ios:c00089xx00000266",
                "GCM_SENDER_ID" : "303600005829"
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.analyticsEnabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }
}
