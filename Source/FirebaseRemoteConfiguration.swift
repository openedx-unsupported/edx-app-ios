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

fileprivate enum Keys: String, RawStringExtractable {
    case valuePropEnabled = "VALUE_PROP_ENABLED"
    case calendarSyncEnabled = "CALENDAR_SYNC_ENABLED"
}

@objc class FirebaseRemoteConfiguration: NSObject {
    @objc static let shared =  FirebaseRemoteConfiguration()
    var isValuePropEnabled: Bool = false
    var isCalendarSyncEnabled: Bool = false
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        let valueProp = remoteConfig.configValue(forKey: Keys.valuePropEnabled.rawValue).boolValue
        let calendarSync = remoteConfig.configValue(forKey: Keys.calendarSyncEnabled.rawValue).boolValue
        
        let dictionary = [
            Keys.valuePropEnabled.rawValue: valueProp,
            Keys.calendarSyncEnabled.rawValue: calendarSync
        ]
        saveRemoteConfig(with: dictionary)
    }
    
    @objc func initialize() {
        guard let remoteConfig = UserDefaults.standard.object(forKey: remoteConfigUserDefaultKey) as? [String: Any], remoteConfig.count > 0 else {
            return
        }
        
        isValuePropEnabled = remoteConfig[Keys.valuePropEnabled] as? Bool ?? false
        isCalendarSyncEnabled = remoteConfig[Keys.calendarSyncEnabled] as? Bool ?? false
    }
    
    private func saveRemoteConfig(with values: [String: Any]) {
        UserDefaults.standard.set(values, forKey: remoteConfigUserDefaultKey)
        UserDefaults.standard.synchronize()
    }
}
