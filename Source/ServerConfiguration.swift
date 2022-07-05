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
    }
    
    @objc static let shared = ServerConfiguration()
    
    var valuePropEnabled: Bool = false
    
    private override init() {
        super.init()
    }
    
    func initialize(json: JSON) {
        guard let dictionary = json.dictionaryObject else { return }
        valuePropEnabled = dictionary[Keys.valuePropEnabled] as? Bool ?? false
    }
}
