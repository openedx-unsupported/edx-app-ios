//
//  UserProfileViewTests.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX

class MockProfilePresenter: UserProfilePresenter {
    let profileStream: OEXStream<UserProfile>
    let tabStream: OEXStream<[ProfileTabItem]>

    weak var delegate: UserProfilePresenterDelegate?

    init(profile: UserProfile, tabs: [ProfileTabItem]) {
        profileStream = OEXStream(value: profile)
        tabStream = OEXStream(value: tabs)
    }

    func refresh() {
        // do nothing
    }
}

class MockPaginator<A>: Paginator {
    typealias Element = A

    let stream: OEXStream<[A]>
    init(values : [A]) {
        self.stream = OEXStream(value: values)
    }

    let hasNext: Bool = false

    func loadMore() {
        // do nothing
    }
}

class UserProfileViewTests: SnapshotTestCase {

    func profileWithPrivacy(_ privacy : UserProfile.ProfilePrivacy) -> UserProfile {
        return UserProfile(username: "Test Person", bio: "Hello I am a lorem ipsum dolor sit amet", parentalConsent: false, countryCode: "de", accountPrivacy: privacy)
    }
    
    func snapshotContentWithPrivacy(_ privacy : UserProfile.ProfilePrivacy) {
        let environment = TestRouterEnvironment().logInTestUser()
        let presenter = MockProfilePresenter(profile: profileWithPrivacy(privacy), tabs: [])
        let controller = UserProfileViewController(environment: environment, presenter: presenter, editable: true)
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

        let tabs = [{(scrollView: UIScrollView) -> TabItem in
            let paginator = AnyPaginator(MockPaginator(values:accomplishments))
            let view = AccomplishmentsView(paginator: paginator, containingScrollView: scrollView) {_ in }
            return TabItem(name: Strings.Accomplishments.title, view: view, identifier: "accomplishments")}]
        let testPresenter = MockProfilePresenter(profile: profile, tabs: tabs)
        let controller = UserProfileViewController(environment: TestRouterEnvironment(), presenter: testPresenter, editable: false)
        
        inScreenNavigationContext(controller) {
            controller.t_chooseTab(identifier: "accomplishments")
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
}
