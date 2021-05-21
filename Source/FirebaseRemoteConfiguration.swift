//
//  FirebaseRemoteConfiguration.swift
//  edX
//
//  Created by Salman on 04/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

private let remoteConfigUserDefaultKey = "remote-config"

protocol RemoteConfigProvider {
    var remoteConfig: FirebaseRemoteConfiguration { get }
}

extension RemoteConfigProvider {
    var remoteConfig: FirebaseRemoteConfiguration {
        return FirebaseRemoteConfiguration.shared
    }
}

@objc class FirebaseRemoteConfiguration: NSObject {
    enum Keys: String, RawStringExtractable {
        case iOS = "ios"
        case valuePropEnabled = "VALUE_PROP_ENABLED"
        case courseDatesCalendarSync = "COURSE_DATES_CALENDAR_SYNC"
    }
    
    @objc static let shared =  FirebaseRemoteConfiguration()
    
    var valuePropEnabled: Bool = false
    var calendarSyncConfiguration = CalendarSyncConfig()
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        let valueProp = remoteConfig.configValue(forKey: Keys.valuePropEnabled.rawValue).boolValue
        let calendarSync = remoteConfig.configValue(forKey: Keys.courseDatesCalendarSync.rawValue).jsonValue as? [String : Any]
        
        let calendarSyncDictionary = calendarSync?[Keys.iOS.rawValue] as? [String : Bool] ?? [:]
        
        if let calendarSyncConfig: CalendarSyncConfig = calendarSyncDictionary.object() {
            calendarSyncConfiguration = calendarSyncConfig
        }
        
        let dictionary: [String : Any] = [
            Keys.valuePropEnabled.rawValue: valueProp,
            Keys.courseDatesCalendarSync.rawValue: calendarSyncDictionary
        ]
        saveRemoteConfig(with: dictionary)
    }
    
    @objc func initialize() {
        guard let remoteConfig = UserDefaults.standard.object(forKey: remoteConfigUserDefaultKey) as? [String: Any], remoteConfig.count > 0 else {
            return
        }
        
        valuePropEnabled = remoteConfig[Keys.valuePropEnabled] as? Bool ?? false
        let calendarSyncDictionary = remoteConfig[Keys.courseDatesCalendarSync] as? [String : Bool] ?? [:]
        
        if let calendarSyncConfig: CalendarSyncConfig = calendarSyncDictionary.object() {
            calendarSyncConfiguration = calendarSyncConfig
        }
    }
    
    private func saveRemoteConfig(with values: [String: Any]) {
        UserDefaults.standard.set(values, forKey: remoteConfigUserDefaultKey)
        UserDefaults.standard.synchronize()
    }
}

fileprivate extension Dictionary where Key == String, Value: Any {
    func object<T: Decodable>() -> T? {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: []) {
            return try? JSONDecoder().decode(T.self, from: data)
        } else {
            return nil
        }
    }
}
