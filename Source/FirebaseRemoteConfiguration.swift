//
//  RemoteConfig.swift
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

fileprivate enum remoteConfigKeys: String, RawStringExtractable {
    case valuePropEnabled = "VALUE_PROP_ENABLED"
}

enum ValuePropState: String {
    case enable = "enable"
    case disable = "disable"
    case none = "none"
}

@objc class FirebaseRemoteConfiguration: NSObject {
    @objc static let shared =  FirebaseRemoteConfiguration()
    var valuePropState: ValuePropState = .none
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        let allkeys = remoteConfig.allKeys(from: RemoteConfigSource.remote)
        if allkeys.contains(remoteConfigKeys.valuePropEnabled.rawValue) {
            let valuePropEnable = remoteConfig.configValue(forKey: remoteConfigKeys.valuePropEnabled.rawValue).boolValue
            valuePropState = valuePropEnable ? ValuePropState.enable : ValuePropState.disable
            UserDefaults.standard.set(valuePropState.rawValue, forKey: remoteConfigUserDefaultKey)
            UserDefaults.standard.synchronize()
        } else {
            valuePropState = .none
        }
    }
    
    @objc func initialize() {
        guard let value = UserDefaults.standard.object(forKey: remoteConfigUserDefaultKey) as? String else {
            return
        }
        
        valuePropState = ValuePropState(rawValue: value) ?? .none
    }
}
