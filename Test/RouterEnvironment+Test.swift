//
//  RouterEnvironment+Test.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit
@testable import edX

extension RouterEnvironment {
    convenience init(interface: OEXInterface? = nil, session: OEXSession = OEXSession(credentialStore: OEXMockCredentialStorage())) {
        self.init(
            analytics: OEXAnalytics(),
            config: OEXConfig(dictionary: [:]),
            dataManager: DataManager(),
            interface: interface,
            networkManager: MockNetworkManager(authorizationHeaderProvider: session, baseURL: NSURL(string: "http://example.com")!),
            session: session,
            styles: OEXStyles()
        )
    }
}
