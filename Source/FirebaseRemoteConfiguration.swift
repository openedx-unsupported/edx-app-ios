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

fileprivate enum keys: String, RawStringExtractable {
    case valuePropEnabled = "VALUE_PROP_ENABLED"
}

@objc class FirebaseRemoteConfiguration: NSObject {
    @objc static let shared =  FirebaseRemoteConfiguration()
    var isValuePropEnabled: Bool = false
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        
        let valueProp = remoteConfig.configValue(forKey: keys.valuePropEnabled.rawValue).boolValue
        
        let dictionary: [String:Any] = [keys.valuePropEnabled.rawValue:valueProp]
        saveRemoteConfig(with: dictionary)
    }
    
    @objc func initialize() {
        guard let remoteConfig = UserDefaults.standard.object(forKey: remoteConfigUserDefaultKey) as? [String: Any], remoteConfig.count > 0 else {
            return
        }
    
        isValuePropEnabled = remoteConfig[keys.valuePropEnabled] as? Bool ?? false
    }
    
    private func saveRemoteConfig(with values: [String: Any]) {
        UserDefaults.standard.set(values, forKey: remoteConfigUserDefaultKey)
        UserDefaults.standard.synchronize()
    }
}
