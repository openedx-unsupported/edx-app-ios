//
//  AppUpgradeConfig.swift
//  edX
//
//  Created by Saeed Bashir on 8/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class AppUpgradeConfig : NSObject {
    
    var URIS:NSArray = []
    
    init(uris: NSArray) {
        self.URIS = uris
    }
    
    func iOSAppStoreURL() -> NSURL? {
        if URIS.count > 0 , let URLString = URIS[0] as? String, let appStoreURL = NSURL(string: URLString) {
            return appStoreURL
        }
        return nil
    }
}

private let key = "APP_UPDATE_URIS"
extension OEXConfig {
    var appUpgradeConfig : AppUpgradeConfig {
        return AppUpgradeConfig(uris: self[key] as? NSArray ?? [])
    }
}