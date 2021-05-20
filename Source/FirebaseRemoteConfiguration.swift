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

struct CalendarSyncConfiguration: Codable {
    var isEnabled: Bool = false
    var isSelfPacedEnabled: Bool = false
    var isInstructorPacedEnabled: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case isEnabled = "ENABLED"
        case isSelfPacedEnabled = "SELF_PACED_ENABLED"
        case isInstructorPacedEnabled = "INSTRUCTOR_PACED_ENABLED"
    }
}

@objc class FirebaseRemoteConfiguration: NSObject {
    enum Keys: String, RawStringExtractable {
        case iOS = "ios"
        case valuePropEnabled = "VALUE_PROP_ENABLED"
        case calendarSyncForCourseDates = "CALENDAR_SYNC_FOR_COURSE_DATES"
    }
    
    @objc static let shared =  FirebaseRemoteConfiguration()
    
    var isValuePropEnabled: Bool = false
    var calendarSyncConfiguration = CalendarSyncConfiguration()
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        let valueProp = remoteConfig.configValue(forKey: Keys.valuePropEnabled.rawValue).boolValue
        let calendarSync = remoteConfig.configValue(forKey: Keys.calendarSyncForCourseDates.rawValue).jsonValue as? [String : Any]
        
        let calendarSyncDictionary = calendarSync?[Keys.iOS.rawValue] as? [String : Bool]
        
        if let configuration: CalendarSyncConfiguration = calendarSyncDictionary?.object() {
            calendarSyncConfiguration = configuration
        }
        
        let dictionary: [String : Any] = [
            Keys.valuePropEnabled.rawValue: valueProp,
            Keys.calendarSyncForCourseDates.rawValue: calendarSyncDictionary ?? [:]
        ]
        saveRemoteConfig(with: dictionary)
    }
    
    @objc func initialize() {
        guard let remoteConfig = UserDefaults.standard.object(forKey: remoteConfigUserDefaultKey) as? [String: Any], remoteConfig.count > 0 else {
            return
        }
        
        isValuePropEnabled = remoteConfig[Keys.valuePropEnabled] as? Bool ?? false
        let calendarSyncDictionary = remoteConfig[Keys.calendarSyncForCourseDates] as? [String : Bool]
        
        if let configuration: CalendarSyncConfiguration = calendarSyncDictionary?.object() {
            calendarSyncConfiguration = configuration
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
