//
//  FirebaseRemoteConfiguration.swift
//  edX
//
//  Created by Salman on 04/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

private let remoteConfigUserDefaultKey = "remote-config"

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
    
    @objc static let shared =  FirebaseRemoteConfiguration()
    
    var calendarSyncConfig = CalendarSyncConfig()
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        let calendarSync = remoteConfig.configValue(forKey: Keys.courseDatesCalendarSync.rawValue).jsonValue as? [String : Any]
        calendarSyncConfig = CalendarSyncConfig(dict: calendarSync)
        
        let dictionary: [String : Any] = [
            Keys.courseDatesCalendarSync.rawValue: calendarSyncConfig.toDictionary()
        ]
        saveRemoteConfig(with: dictionary)
    }
    
    @objc func initialize() {
        guard let remoteConfig = UserDefaults.standard.object(forKey: remoteConfigUserDefaultKey) as? [String: Any], remoteConfig.count > 0 else {
            return
        }
        
        let calendarSync = remoteConfig[Keys.courseDatesCalendarSync] as? [String : Any]
        calendarSyncConfig = CalendarSyncConfig(dict: calendarSync)
    }
    
    private func saveRemoteConfig(with values: [String: Any]) {
        UserDefaults.standard.set(values, forKey: remoteConfigUserDefaultKey)
        UserDefaults.standard.synchronize()
    }
}
