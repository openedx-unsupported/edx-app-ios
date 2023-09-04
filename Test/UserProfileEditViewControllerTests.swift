//
//  UserProfileEditViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 10/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
@testable import edX

class UserProfileEditViewControllerTests : SnapshotTestCase {
    
    var profile : UserProfile {
        return UserProfile(username: "Test Person", bio: "Hello I am a lorem ipsum dolor sit amet", parentalConsent: false, countryCode: "de", accountPrivacy: .Public)
    }
    
    func testSnapshotPublic() {
        let controller = UserProfileEditViewController(profile: profile, environment: TestRouterEnvironment())
        inScreenNavigationContext(controller, action: { () -> () in
            assertSnapshotValidWithContent(controller.navigationController!)
        })
    }

}