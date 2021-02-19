//
//  FCMProvider.swift
//  edX
//
//  Created by Saeed Bashir on 9/30/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation

class FCMProvider: NSObject, OEXPushProvider {

    //MARK:- OEXPushProvider Methods
    func sessionStarted(with user: OEXUserDetails, settingsManager: OEXPushSettingsManager) {
        // Nothing useful to do at this moment so ignore
    }

    func sessionEnded() {
        // Nothing useful to do at this moment so ignore
    }

    func didRegisterForRemoteNotifications(withDeviceToken device: Data) {
        Messaging.messaging().apnsToken = device
    }

    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        // Nothing useful to do at this moment so ignore
    }
}
