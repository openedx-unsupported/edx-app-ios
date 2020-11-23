//
//  RemoteConfig.swift
//  edX
//
//  Created by Salman on 04/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

protocol RemoteConfigProvider {
  var remoteConfig: FirebaseRemoteConfiguration { get }
}

extension RemoteConfigProvider {
  var remoteConfig: FirebaseRemoteConfiguration {
    return FirebaseRemoteConfiguration.shared
  }
}

@objc class FirebaseRemoteConfiguration: NSObject {
    @objc static let shared =  FirebaseRemoteConfiguration()
    
    private override init() {
        super.init()
    }
    
    @objc func initialize(remoteConfig: RemoteConfig) {
        //TODO: Make the required changes here. Not using the Firebase Remote config at this moment
    }
    
    @objc func initialize() {
        //TODO: Make the required changes here. Not using the Firebase Remote config at this moment
    }
}

