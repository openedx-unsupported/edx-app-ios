//
//  AppUpgradeConfig.swift
//  edX
//
//  Created by Saeed Bashir on 8/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class AppStoreConfig : NSObject {
    
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

private let appUpdateURIKey = "APP_UPDATE_URIS"
private let appReviewURIKey = "APP_REVIEW_URI"

extension OEXConfig {
    
    var appUpgradeConfig : AppStoreConfig {
        return AppStoreConfig(uris: self[appUpdateURIKey] as? NSArray ?? [])
    }
    
    var appReviewURI : String? {
        return string(forKey: appReviewURIKey)
    }
}
