//
//  FirebaseRemoteConfiguration.swift
//  edX
//
//  Created by Salman on 04/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

let NOTIFICATION_FIREBASE_REMOTE_CONFIG = "FirebaseRemoteConfigNotification"

public protocol RemoteConfigProvider {
    var remoteConfig: FirebaseRemoteConfiguration { get }
}

public extension RemoteConfigProvider {
    var remoteConfig: FirebaseRemoteConfiguration {
        return FirebaseRemoteConfiguration.shared
    }
}

@objc public class FirebaseRemoteConfiguration: NSObject {
    enum Keys: String, RawStringExtractable {
        case courseDatesCalendarSync = "COURSE_DATES_CALENDAR_SYNC"
    }
    
    @objc static let shared = FirebaseRemoteConfiguration()
    
    var calendarSyncConfig: CalendarSyncConfig
    
    private override init() {
        self.calendarSyncConfig = CalendarSyncConfig()
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        let calendarSync = remoteConfig.configValue(forKey: Keys.courseDatesCalendarSync.rawValue).jsonValue as? [String : Any]
        calendarSyncConfig = CalendarSyncConfig(dict: calendarSync)

        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_FIREBASE_REMOTE_CONFIG)))
    }
}
