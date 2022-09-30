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
    }
    
    @objc static let shared = ServerConfiguration()
    
    private(set) var valuePropEnabled: Bool = false
    
    private override init() {
        super.init()
    }
    
    func initialize(json: JSON) {
        guard let dictionary = json.dictionaryObject,
              let configString = dictionary[Keys.config] as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options : []) as? Dictionary<String,Any> else { return }

        valuePropEnabled = config[Keys.valuePropEnabled] as? Bool ?? false
    }
}
