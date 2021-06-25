//
//  BrazeProvider.swift
//  edX
//
//  Created by Saeed Bashir on 5/20/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

class BrazeProvider: NSObject, OEXPushProvider {

    //MARK:- OEXPushProvider Methods
    func sessionStarted(with user: OEXUserDetails, settingsManager: OEXPushSettingsManager) {
        // Nothing useful to do at this moment so ignore
    }

    func sessionEnded() {
        // Nothing useful to do at this moment so ignore
    }

    func didRegisterForRemoteNotifications(withDeviceToken device: Data) {
        Analytics.shared().registeredForRemoteNotifications(withDeviceToken: device)
    }

    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        // Nothing useful to do at this moment so ignore
    }
}
