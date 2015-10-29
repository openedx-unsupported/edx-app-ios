//
//  UserProfileViewTests.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX

class UserProfileViewTests: SnapshotTestCase {

    func profileWithPrivacy(privacy : UserProfile.ProfilePrivacy) -> UserProfile {
        return UserProfile(username: "Test Person", bio: "Hello I am a lorem ipsum dolor sit amet", parentalConsent: false, countryCode: "de", accountPrivacy: privacy)
    }
    
    func snapshotContentWithPrivacy(privacy : UserProfile.ProfilePrivacy) {
        let manager = MockUserProfileManager(profile: profileWithPrivacy(privacy))
        let feed = manager.feedForUser("test")
        let env = UserProfileViewController.Environment(networkManager: MockNetworkManager(), router: nil)
        let controller = UserProfileViewController(environment: env, feed: feed)
        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }
    
    func testSnapshotContent() {
        snapshotContentWithPrivacy(.Public)
    }
    
    func testSnapshotContentPrivateProfile() {
        snapshotContentWithPrivacy(.Private)
    }
}
