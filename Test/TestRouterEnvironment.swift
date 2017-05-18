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
    let mockCourseDataManager: MockCourseDataManager
    let mockReachability : MockReachability
    let mockEnrollmentManager: MockEnrollmentManager

    init(
        config : OEXConfig = OEXConfig(dictionary: [:]),
        interface: OEXInterface? = nil)
    {
        mockStorage = OEXMockCredentialStorage()
        let session = OEXSession(credentialStore: mockStorage)
        let mockNetworkManager = MockNetworkManager(authorizationHeaderProvider: session, baseURL: NSURL(string:"http://example.com")! as URL)
        self.mockNetworkManager = mockNetworkManager
        eventTracker = MockAnalyticsTracker()
        mockReachability = MockReachability()

        let analytics = OEXAnalytics()
        
        
        let mockEnrollmentManager = MockEnrollmentManager(interface: interface, networkManager: mockNetworkManager, config: config)
        self.mockEnrollmentManager = mockEnrollmentManager
        
        let mockCourseDataManager = MockCourseDataManager(
            analytics: analytics,
            enrollmentManager: mockEnrollmentManager,
            interface: interface,
            networkManager: mockNetworkManager,
            session: session
        )
        self.mockCourseDataManager = mockCourseDataManager
        
        let dataManager = DataManager(
            courseDataManager: mockCourseDataManager,
            enrollmentManager: mockEnrollmentManager,
            interface: interface,
            pushSettings: OEXPushSettingsManager(),
            userProfileManager:UserProfileManager(networkManager: mockNetworkManager, session: session),
            userPreferenceManager: UserPreferenceManager(networkManager: mockNetworkManager)
        )
        
        super.init(analytics: analytics,
            config: config,
            dataManager: dataManager,
            interface: interface,
            networkManager: mockNetworkManager,
            reachability: mockReachability,
            session: session,
            styles: OEXStyles())
        
        self.analytics.add(eventTracker)
    }
    
    @discardableResult func logInTestUser() -> TestRouterEnvironment {
        mockStorage.storedAccessToken = OEXAccessToken.fake()
        mockStorage.storedUserDetails = OEXUserDetails.freshUser()
        self.session.loadTokenFromStore()
        return self
    }
    
}
