//
//  OEXConfig.swift
//  edX
//
//  Created by Michael Katz on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

protocol ConfigurationKey: RawValueExtractable {}

enum CompositeConfigurationKey: String, ConfigurationKey {
    case TwitterKey = "TWITTER"
}


//MARK: - Basic & Helper Operations
extension OEXConfig {
    subscript(value: ConfigurationKey) -> Any? {
        return self.objectForKey(value.rawValue)
    }

}

//MARK: - 3rd Party Services Configurations
extension OEXConfig {

    var twitterConfiguration: TwitterConfiguration? {
        if let twitterDictionary = self[CompositeConfigurationKey.TwitterKey] as? NSDictionary {
            return TwitterConfiguration(twitterDictionary)
        }
        return nil
    }
}