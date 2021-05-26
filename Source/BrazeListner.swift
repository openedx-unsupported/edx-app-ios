//
//  BrazeListner.swift
//  edX
//
//  Created by Saeed Bashir on 5/20/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

@objc class BrazeListner: NSObject, OEXPushListener {

    typealias Environment = OEXSessionProvider & OEXRouterProvider & OEXConfigProvider
    var environment: Environment

    @objc init(environment: Environment){
        self.environment = environment
    }

    func didReceiveLocalNotification(userInfo: [AnyHashable : Any] = [:]) {

        //Implementation for local Notification
    }


    func didReceiveRemoteNotification(userInfo: [AnyHashable : Any] = [:], application: UIApplication?, completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) {
        guard let application = application, let dictionary = userInfo as? [String: Any], isBrazeNotification(userinfo: userInfo) else { return }
        Appboy.sharedInstance()?.register(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)

        let link = PushLink(dictionary: dictionary)
        DeepLinkManager.sharedInstance.processNotification(with: link, environment: environment)
    }

    private func isBrazeNotification(userinfo: [AnyHashable : Any]) -> Bool {
        //A push notification sent from the braze has a key ab in it like ab = {c = "c_value";};
        let appboy = userinfo["ab"] as? [String : Any]
        return appboy?.count ?? 0 > 0
    }
}
