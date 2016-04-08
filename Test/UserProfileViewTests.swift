//
//  UserProfileViewTests.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX

class MockProfilePresenter: UserProfilePresenter {
    let profileStream: Stream<UserProfile>
    let tabStream: Stream<[TabItem]>

    weak var delegate: UserProfilePresenterDelegate?

    init(profile: UserProfile, tabs: [TabItem]) {
        profileStream = Stream(value: profile)
        tabStream = Stream(value: tabs)
    }

    func refresh() {
        // do nothing
    }
}

class UserProfileViewTests: SnapshotTestCase {

    func profileWithPrivacy(privacy : UserProfile.ProfilePrivacy) -> UserProfile {
        return UserProfile(username: "Test Person", bio: "Hello I am a lorem ipsum dolor sit amet", parentalConsent: false, countryCode: "de", accountPrivacy: privacy)
    }
    
    func snapshotContentWithPrivacy(privacy : UserProfile.ProfilePrivacy) {
        let presenter = MockProfilePresenter(profile: profileWithPrivacy(privacy), tabs: [])
        let controller = UserProfileViewController(environment: TestRouterEnvironment(), presenter: presenter, editable: true)
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

    func testVisibleAccomplishments() {
        let profile = profileWithPrivacy(.Public)
        let image = RemoteImageJustImage(image: UIImage(testImageNamed: "sample-badge"))

        let accomplishments = [
            Accomplishment(image: image, title: "Some Cool Thing I did", detail: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ", date: NSDate.stableTestDate(), shareURL: NSURL(string:"https://whatever")!),
            Accomplishment(image: image, title: "Some Other Thing I did", detail: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ", date: NSDate.stableTestDate(), shareURL: NSURL(string:"https://whatever")!)
        ]

        let tabs = [TabItem(name: Strings.Accomplishments.title,
                           view: AccomplishmentsView(accomplishments: accomplishments) {_ in },
                           identifier: "accomplishments")]
        let testPresenter = MockProfilePresenter(profile: profile, tabs: tabs)
        let controller = UserProfileViewController(environment: TestRouterEnvironment(), presenter: testPresenter, editable: false)
        
        inScreenNavigationContext(controller) {
            controller.t_chooseTab("accomplishments")
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
}
