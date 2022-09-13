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
        case iapConfig = "iap_config"
    }
    
    @objc static let shared = ServerConfiguration()
    
    private(set) var valuePropEnabled: Bool = false
    private(set) var iapConfig: IAPConfig? = nil
    
    private override init() {
        super.init()
    }
    
    func initialize(json: JSON) {
        guard let dictionary = json.dictionaryObject else { return }
        valuePropEnabled = dictionary[Keys.valuePropEnabled] as? Bool ?? false

        if let iapDict = dictionary[Keys.iapConfig] as? Dictionary<String, Any> {
            iapConfig = IAPConfig(dictionary: iapDict)
        }
    }
}

class IAPConfig: NSObject {

    enum Keys: String, RawStringExtractable {
        case enabled = "enebled"
        case experimentEnabled = "experiment_enabled"
    }

    private(set) var enabled: Bool = false
    private(set) var experimentEnabled: Bool = false

    init(dictionary: Dictionary<String, Any>) {
        enabled = dictionary[Keys.enabled] as? Bool ?? false
        experimentEnabled = dictionary[Keys.experimentEnabled] as? Bool ?? false
    }

    var enabledforUser: Bool {
        return enabled && experimentEnabled && !(OEXSession.shared()?.currentUser?.isFromControlGroup ?? true)
    }
}

extension OEXUserDetails {
    var isFromControlGroup: Bool {
        guard let userID = userId?.intValue else { return true }
        return userID % 2 == 0
    }
}
