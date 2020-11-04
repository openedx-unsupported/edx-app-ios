//
//  RemoteConfig.swift
//  edX
//
//  Created by Salman on 04/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

fileprivate enum AppThemeKeys: String, RawStringExtractable {
    case icon = "icon"
    case font = "font"
    case color = "color"
    case mode = "mode"
}

fileprivate enum FontKeys: String, RawStringExtractable {
    case name = "name"
    case enable = "enabled"
}

fileprivate enum ColorKeys: String, RawStringExtractable {
    case name = "name"
    case enable = "enabled"
}

@objc class FirebaseRemoteConfiguration: NSObject {
    @objc let appTheme: ThemeConfig?
    
    @objc init(remoteConfig: RemoteConfig) {
        
        let appThemeConfigKey = "app_theme"
        let dict = remoteConfig[appThemeConfigKey].jsonValue as? [String:AnyObject] ?? [:]
        appTheme = ThemeConfig(dictionary: dict)
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
        enabled = dictionary[FontKeys.enable] as? Bool ?? false
        name = dictionary[FontKeys.name] as? String
    }
}

class ColorConfig: NSObject {
    let enabled: Bool
    let name: String?
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[FontKeys.enable] as? Bool ?? false
        name = dictionary[FontKeys.name] as? String
    }
}
