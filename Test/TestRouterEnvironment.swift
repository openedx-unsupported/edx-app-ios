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
    let mockReachability : MockReachability

    init(
        config : OEXConfig = OEXConfig(dictionary: [:]),
        dataManager : DataManager = DataManager(),
        interface: OEXInterface? = nil)
    {
        mockStorage = OEXMockCredentialStorage()
        let session = OEXSession(credentialStore: mockStorage)
        mockNetworkManager = MockNetworkManager(authorizationHeaderProvider: session, baseURL: NSURL(string:"http://example.com")!)
        eventTracker = MockAnalyticsTracker()
        mockReachability = MockReachability()
        
        super.init(analytics: OEXAnalytics(),
            config: config,
            dataManager: dataManager,
            interface: interface,
            networkManager: mockNetworkManager,
            reachability: mockReachability,
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