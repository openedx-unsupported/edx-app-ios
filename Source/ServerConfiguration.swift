//
//  ServerConfiguration.swift
//  edX
//
//  Created by MuhammadUmer on 01/07/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

public protocol ServerConfigProvider {
    var serverConfig: ServerConfiguration { get }
}

public extension ServerConfigProvider {
    var serverConfig: ServerConfiguration {
        return ServerConfiguration.shared
    }
}

@objc public class ServerConfiguration: NSObject {
    private enum Keys: String, RawStringExtractable {
        case valuePropEnabled = "value_prop_enabled"
        case config = "config"
        case iapConfig = "iap_config"
    }
    
    @objc static let shared = ServerConfiguration()
    
    private(set) var valuePropEnabled: Bool = false
    private(set) var iapConfig: IAPConfig? = nil
    
    private override init() {
        super.init()
    }
    
    func initialize(json: JSON) {
        guard let dictionary = json.dictionaryObject,
              let configString = dictionary[Keys.config] as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options : []) as? Dictionary<String,Any> else { return }

        valuePropEnabled = config[Keys.valuePropEnabled] as? Bool ?? false

        if let iapDict = config[Keys.iapConfig] as? Dictionary<String, Any> {
            iapConfig = IAPConfig(dictionary: iapDict)
        }
    }
}

enum IAPExperiementGroup: String {
    case control
    case treatment
}

class IAPConfig: NSObject {

    enum Keys: String, RawStringExtractable {
        case enabled = "enabled"
        case experimentEnabled = "experiment_enabled"
        case disabledVersions = "ios_disabled_versions"
        case allowedUsers = "allowed_users"
    }

    private(set) var enabled: Bool = false
    private(set) var experimentEnabled: Bool = false
    private var disabledVersions: [String] = []
    private var allowedUsers: [String] = []

    init(dictionary: Dictionary<String, Any>) {
        enabled = dictionary[Keys.enabled] as? Bool ?? false
        experimentEnabled = dictionary[Keys.experimentEnabled] as? Bool ?? false
        disabledVersions = dictionary[Keys.disabledVersions] as? [String] ?? []
        allowedUsers = dictionary[Keys.allowedUsers] as? [String] ?? []
        
        // if allowed_users have the username of logged in user, enable the payment by ignoring experiment_enabled flag
        if let userName = OEXSession.shared()?.currentUser?.username, allowedUsers.contains(userName) {
            experimentEnabled = false
        }
        else {
            enabled = false
        }
        
        // if allowed_users value is all_users then falback to the original settings of the iap_config
        if allowedUsers.contains("all_users") {
            enabled = dictionary[Keys.enabled] as? Bool ?? false
            experimentEnabled = dictionary[Keys.experimentEnabled] as? Bool ?? false
        }
        
        if disabledVersions.contains(Bundle.main.oex_shortVersionString()) {
            enabled = false
        }
    }

    var enabledforUser: Bool {
        if experimentEnabled {
            return enabled && !(OEXSession.shared()?.currentUser?.isFromControlGroup ?? true)
        }

        return enabled
    }
    
    var experimentGroup: IAPExperiementGroup? {
        if experimentEnabled && enabled {
            return OEXSession.shared()?.currentUser?.isFromControlGroup ?? false ? .control : .treatment
        }
        
        return nil
    }
}

extension OEXUserDetails {
    var isFromControlGroup: Bool {
        guard let userID = userId?.intValue else { return true }
        return userID % 2 == 0
    }
}
