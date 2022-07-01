//
//  AppConfiguration.swift
//  edX
//
//  Created by MuhammadUmer on 01/07/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

private let appConfigUserDefaultKey = "app-config"

public protocol AppConfigProvider {
    var appConfig: AppConfiguration { get }
}

public extension AppConfigProvider {
    var appConfig: AppConfiguration {
        return AppConfiguration.shared
    }
}

@objc public class AppConfiguration: NSObject {
    private enum Keys: String, RawStringExtractable {
        case valuePropEnabled = "value_prop_enabled"
    }
    
    @objc static let shared = AppConfiguration()
    
    var valuePropEnabled: Bool = false
    
    private override init() {
        super.init()
        initialize()
    }
    
    func initialize(json: JSON) {
        valuePropEnabled = true
        guard let dictionary = json.dictionaryObject else { return }
        
        valuePropEnabled = dictionary[Keys.valuePropEnabled] as? Bool ?? false
        
        let appConfig: [String : Any] = [
            Keys.valuePropEnabled.rawValue: valuePropEnabled,
        ]
        saveRemoteConfig(with: appConfig)
    }
    
    @objc func initialize() {
        guard let appConfig = UserDefaults.standard.object(forKey: appConfigUserDefaultKey) as? [String: Any],
              !appConfig.isEmpty else { return }
        valuePropEnabled = appConfig[Keys.valuePropEnabled] as? Bool ?? false
    }
    
    private func saveRemoteConfig(with values: [String: Any]) {
        UserDefaults.standard.set(values, forKey: appConfigUserDefaultKey)
        UserDefaults.standard.synchronize()
    }
}
