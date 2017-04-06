//
//  MockUserProfileManager.swift
//  edX
//
//  Created by Akiva Leffert on 10/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

import edX

class MockUserProfileManager : UserProfileManager {
    fileprivate let feed : Feed<UserProfile>
    
    init() {
        self.feed = Feed(refreshTrigger: {_ in })
        super.init(networkManager: MockNetworkManager(), session: OEXSession(credentialStore: OEXMockCredentialStorage()))
    }
    
    init(profile : UserProfile) {
        self.feed = Feed(refreshTrigger: { (stream) -> Void in
            stream.backWithStream(OEXStream(value: profile))
        })
        super.init(networkManager : MockNetworkManager(), session : OEXSession(credentialStore: OEXMockCredentialStorage()))
    }
    override func feedForUser(username: String) -> Feed<UserProfile> {
        return self.feed
    }
}
