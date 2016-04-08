//
//  UserProfileNetworkPresenterTests.swift
//  edX
//
//  Created by Akiva Leffert on 4/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest

@testable import edX

class UserProfileNetworkPresenterTests: XCTestCase {

    var sampleProfile: UserProfile {
        return UserProfile(username: "some person", bio: "Test bio")
    }

    private func presenterWithProfile(profile: UserProfile, badges: [BadgeAssertion]) -> UserProfilePresenter {
        let config = OEXConfig(dictionary: ["BADGES_ENABLED": true])
        let environment = TestRouterEnvironment(config: config)
        environment.mockNetworkManager.interceptWhenMatching({_ in true}) { () -> (NSData?, [BadgeAssertion]) in
            (nil, badges)
        }
        environment.mockNetworkManager.interceptWhenMatching({_ in true}) { () -> (NSData?, UserProfile) in
            (nil, profile)
        }
        return UserProfileNetworkPresenter(environment: environment, username: "test")
    }

    func testAchievementsNoTabWhenNoBadges() {
        let presenter = presenterWithProfile(sampleProfile, badges: [])
        waitForStream(presenter.tabStream) {tabs in
            XCTAssertEqual(tabs.value!.count, 0)
        }
    }

    func testAchievementsTabExistsWhenBadges() {
        let presenter = presenterWithProfile(sampleProfile, badges:
            [
                BadgeAssertion(evidence: NSURL(string:"http://somebadge.com")!, imageURL: "http://example.com/image", spec: BadgeSpec(name: "Good job!")),
                BadgeAssertion(evidence: NSURL(string:"http://somebadge.com")!, imageURL: "http://example.com/image", spec: BadgeSpec(name: "Good job!"))
            ]
        )
        waitForStream(presenter.tabStream) {tabs in
            XCTAssertEqual(tabs.value!.count, 1)
            let tab = tabs.value?.firstObjectMatching { $0.identifier == UserProfileNetworkPresenter.AccomplishmentsTabIdentifier }
            XCTAssertNotNil(tab)
        }
    }

    func testProfileLoads() {
        let presenter = presenterWithProfile(sampleProfile, badges: [])
        waitForStream(presenter.profileStream) {profile in
            XCTAssertEqual(profile.value!.bio, self.sampleProfile.bio)
            XCTAssertEqual(profile.value!.username, self.sampleProfile.username)
        }
    }
}
