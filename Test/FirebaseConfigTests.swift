//
//  FirebaseConfigTests.swift
//  edXTests
//
//  Created by Saeed Bashir on 8/28/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

@testable import edX

let apiKey = "APebSdWSu456EDkUk0imSGqetnOznbZv22QRiq1"
let clientID = "302611111829-s11900000000tdhcbj9876548888qur3.apps.googleusercontent.com"
let googleAppID = "3:902600000000:ios:c00089xx00000266"
let gcmSenderID = "303600005829"

class FirebaseConfigTests: XCTestCase {

    func testNoFirebaseConfig() {
        let config = OEXConfig(dictionary:[:])
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceSegment)
        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceFirebase)
        XCTAssertEqual(config.firebaseConfig.analyticsSource, AnalyticsSource.none)
    }

    func testEmptyFirebaseConfig() {
        let config = OEXConfig(dictionary:["FIREBASE":[:] as [String : Any]])
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceFirebase)
        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceSegment)
        XCTAssertEqual(config.firebaseConfig.analyticsSource, AnalyticsSource.none)
    }

    func testFirebaseConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "ANALYTICS_ENABLED": true,
                "ANALYTICS_SOURCE": "segment",
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceFirebase)
        XCTAssertTrue(config.firebaseConfig.isAnalyticsSourceSegment)
    }

    func testFirebaseDisableConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": false,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }

    func testFirebaseDisableAnalytics() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }

    func testFirebaseDisableCloudMessaging() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": false,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]

        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }
    
    func testFirebaseAPIKey() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertEqual(config.firebaseConfig.apiKey, apiKey)
    }
    
    func testFirebaseClientID() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertEqual(config.firebaseConfig.cliendID, clientID)
    }
    
    func testFirebaseGoogleAppID() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertEqual(config.firebaseConfig.googleAppID, googleAppID)
    }
    
    func testFirebaseGCMSenderID() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
        XCTAssertEqual(config.firebaseConfig.gcmSenderID, gcmSenderID)
    }
    
    func testFirebaseRequiredKeysAvailable() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertTrue(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertTrue(config.firebaseConfig.enabled)
        XCTAssertTrue(config.firebaseConfig.cloudMessagingEnabled)
    }
    
    func testFirebaseRequiredKeysNotAvailable() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": false,
            ]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }
    
    func testFirebaseRequiredKeyMissing() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        XCTAssertFalse(config.firebaseConfig.requiredKeysAvailable)
        XCTAssertFalse(config.firebaseConfig.enabled)
        XCTAssertFalse(config.firebaseConfig.cloudMessagingEnabled)
    }
    
    func testFirebaseDisableIfSegmentEnable() {
        let configDictionary = [
            "FIREBASE" : [
                "ENABLED": true,
                "CLOUD_MESSAGING_ENABLED": true,
                "API_KEY" : apiKey,
                "CLIENT_ID" : clientID,
                "GOOGLE_APP_ID" : googleAppID,
                "GCM_SENDER_ID" : gcmSenderID
            ] as [String : Any],
            
            "SEGMENT_IO": [
                "ENABLED": true,
                "SEGMENT_IO_WRITE_KEY": "p910192UHD101010nY0000001Kb00GFcz'"
            ] as [String : Any]
        ]
        
        let config = OEXConfig(dictionary: configDictionary)
        let firebaseEnable = config.firebaseConfig.enabled && !(config.segmentConfig?.isEnabled ?? false)
        XCTAssertTrue(config.segmentConfig?.isEnabled ?? false)
        XCTAssertFalse(firebaseEnable)
    }

    func testAnalyticsSourceNoneConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ANALYTICS_SOURCE": "none",
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)

        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceSegment)
        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceFirebase)
        XCTAssertEqual(config.firebaseConfig.analyticsSource, AnalyticsSource.none)
    }

    func testAnalyticsSourceSegmentConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ANALYTICS_SOURCE": "segment",
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)

        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceFirebase)
        XCTAssertTrue(config.firebaseConfig.isAnalyticsSourceSegment)
        XCTAssertEqual(config.firebaseConfig.analyticsSource, AnalyticsSource.segment)
    }

    func testAnalyticsSourceFirebaseConfig() {
        let configDictionary = [
            "FIREBASE" : [
                "ANALYTICS_SOURCE": "firebase",
            ]
        ]

        let config = OEXConfig(dictionary: configDictionary)

        XCTAssertFalse(config.firebaseConfig.isAnalyticsSourceSegment)
        XCTAssertTrue(config.firebaseConfig.isAnalyticsSourceFirebase)
        XCTAssertEqual(config.firebaseConfig.analyticsSource, AnalyticsSource.firebase)
    }
}
