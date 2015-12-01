//
//  TestRouterEnvironment.swift
//  edX
//
//  Created by Akiva Leffert on 12/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
@testable import edX

class TestRouterEnvironment : RouterEnvironment {
    let mockNetworkManager : MockNetworkManager
    let mockStorage : OEXMockCredentialStorage
    let eventTracker : MockAnalyticsTracker

    init(interface: OEXInterface? = nil) {
        mockStorage = OEXMockCredentialStorage()
        let session = OEXSession(credentialStore: mockStorage)
        mockNetworkManager = MockNetworkManager(authorizationHeaderProvider: session, baseURL: NSURL(string:"http://example.com")!)
        eventTracker = MockAnalyticsTracker()
        
        super.init(analytics: OEXAnalytics(),
            config: OEXConfig(dictionary: [:]),
            dataManager: DataManager(),
            interface: interface,
            networkManager: mockNetworkManager,
            session: session,
            styles: OEXStyles())
        
        self.analytics.addTracker(eventTracker)
    }
    
    func logInTestUser() -> TestRouterEnvironment {
        mockStorage.storedAccessToken = OEXAccessToken.fakeToken()
        mockStorage.storedUserDetails = OEXUserDetails.freshUser()
        self.session.loadTokenFromStore()
        return self
    }
    
}