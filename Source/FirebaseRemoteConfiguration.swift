//
//  RemoteConfig.swift
//  edX
//
//  Created by Salman on 04/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

fileprivate let appThemeConfigKey = "app_theme"

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
    @objc static let sharedRemoteConfig =  FirebaseRemoteConfiguration()
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        
        guard let dictionary = UserDefaults.standard.value(forKey: appThemeConfigKey) as? [String:AnyObject] else {
            let remoteDictionary = remoteConfig[appThemeConfigKey].jsonValue as? [String:AnyObject] ?? [:]
            appTheme = ThemeConfig(dictionary: remoteDictionary)
            UserDefaults.standard.set(remoteDictionary, forKey: appThemeConfigKey)
            return
        }
    
        appTheme = ThemeConfig(dictionary: dictionary)
        let remoteDict = remoteConfig[appThemeConfigKey].jsonValue as? [String:AnyObject] ?? [:]
        UserDefaults.standard.set(remoteDict, forKey: appThemeConfigKey)
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
