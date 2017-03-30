//
//  ServerChangedChecker.swift
//  edX
//
//  Created by Akiva Leffert on 2/26/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation


@objc class ServerChangedChecker : NSObject {
    private let defaultsKey = "OEXLastUsedAPIHostURL"

    private var lastUsedAPIHostURL : NSURL? {
        get {
            return UserDefaults.standard.url(forKey: defaultsKey) as NSURL?
        }
        set {
            UserDefaults.standard.set(newValue as URL?, forKey: defaultsKey)
        }
    }

    func logoutIfServerChanged(config: OEXConfig, logoutAction : (Void) -> Void) {
        if let lastURL = lastUsedAPIHostURL, let currentURL = config.apiHostURL(), lastURL as URL != currentURL {
            logoutAction()
            OEXFileUtility.nukeUserData()
        }
        lastUsedAPIHostURL = config.apiHostURL()! as NSURL
    }

    func logoutIfServerChanged() {
        logoutIfServerChanged(config: OEXConfig(appBundleData: ())) {
            OEXSession().closeAndClear()
        }
    }
}
