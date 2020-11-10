//
//  RemoteConfig.swift
//  edX
//
//  Created by Salman on 04/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

private let appThemeConfigKey = "app_theme"

protocol RemoteConfigProvider {
  var remoteConfig: FirebaseRemoteConfiguration { get }
}

extension RemoteConfigProvider {
  var remoteConfig: FirebaseRemoteConfiguration {
    return FirebaseRemoteConfiguration.shared
  }
}

fileprivate enum AppThemeKeys: String, RawStringExtractable {
    case icon = "icon"
    case font = "font"
    case color = "color"
    case mode = "mode"
    case name = "name"
    case enable = "enabled"
}

@objc class FirebaseRemoteConfiguration: NSObject {
    @objc var appTheme: ThemeConfig?
    @objc static let shared =  FirebaseRemoteConfiguration()
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        
        guard let themeDictionary = remoteConfig[appThemeConfigKey].jsonValue as? [String:AnyObject], !themeDictionary.isEmpty else {
            return
        }
        
        if appTheme == nil {
            appTheme = ThemeConfig(dictionary: themeDictionary)
        }
        UserDefaults.standard.set(themeDictionary, forKey: appThemeConfigKey)
        UserDefaults.standard.synchronize()
    }
    
    @objc func initialize() {
        guard let dictionary = UserDefaults.standard.object(forKey: appThemeConfigKey) as? [String:AnyObject] else {
            return
        }
        appTheme = ThemeConfig(dictionary: dictionary)
    }
}

class ThemeConfig: NSObject {
    let fontConfig: FontConfig
    let colorConfig: ColorConfig
    let icon: String?
    let mode: String?
    
    init(dictionary: [String: AnyObject]) {
        fontConfig = FontConfig(dictionary: dictionary[AppThemeKeys.font] as? [String:AnyObject] ?? [:])
        colorConfig = ColorConfig(dictionary: dictionary[AppThemeKeys.color] as? [String:AnyObject] ?? [:])
        icon = dictionary[AppThemeKeys.icon] as? String
        mode = dictionary[AppThemeKeys.mode] as? String
    }
}

class FontConfig: NSObject {
    let enabled: Bool
    let name: String?
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[AppThemeKeys.enable] as? Bool ?? false
        name = dictionary[AppThemeKeys.name] as? String
    }
}

class ColorConfig: NSObject {
    let enabled: Bool
    let name: String?
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[AppThemeKeys.enable] as? Bool ?? false
        name = dictionary[AppThemeKeys.name] as? String
    }
}
