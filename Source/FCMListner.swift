//
//  FCMListner.swift
//  edX
//
//  Created by Salman on 07/11/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import UIKit

@objc class FCMListner: NSObject, OEXPushListener {
    
    typealias Environment = OEXSessionProvider & OEXRouterProvider & OEXConfigProvider
    var environment: Environment

    @objc init(environment: Environment){
        self.environment = environment
    }
    
    func didReceiveLocalNotification(userInfo: [AnyHashable : Any] = [:]) {
        
        //Implementation for local Notification
    }
    
    func didReceiveRemoteNotification(userInfo: [AnyHashable : Any] = [:]) {
        guard let dictionary = userInfo as? [String: Any] else { return }
        let link = PushLink(dictionary: dictionary)
        DeepLinkManager.sharedInstance.processNotification(with: link, environment: environment)
    }
}
