//
//  UserProfilePresenter.swift
//  edX
//
//  Created by Akiva Leffert on 4/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension Accomplishment {
    convenience init(badge: BadgeAssertion, networkManager: NetworkManager) {
        let image = RemoteImageImpl(url: badge.imageURL, networkManager: networkManager, placeholder: nil, persist: false)
        self.init(image: image, title: badge.badgeClass.name, detail: badge.badgeClass.detail, date: badge.created, shareURL: badge.assertionURL)
    }
}

protocol UserProfilePresenterDelegate : class {
    func presenter(presenter: UserProfilePresenter, choseShareURL url: NSURL)
}

protocol UserProfilePresenter {

    var profileStream: Stream<UserProfile> { get }
    var tabStream: Stream<[TabItem]> { get }
    func refresh() -> Void

    weak var delegate: UserProfilePresenterDelegate? { get }
}

class UserProfileNetworkPresenter : UserProfilePresenter {
    typealias Environment = protocol<OEXConfigProvider, DataManagerProvider, NetworkManagerProvider>

    static let AccomplishmentsTabIdentifier = "AccomplishmentsTab"
    private let profileFeed: Feed<UserProfile>
    private let environment: Environment
    private let username: String

    var profileStream: Stream<UserProfile> {
        return profileFeed.output
    }

    weak var delegate: UserProfilePresenterDelegate?

    init(environment: Environment, username: String) {
        self.profileFeed = environment.dataManager.userProfileManager.feedForUser(username)
        self.environment = environment
        self.username = username
        self.refresh()
    }

    func refresh() {
        profileFeed.refresh()
    }

    lazy var tabStream: Stream<[TabItem]> = {
        if self.environment.config.badgesEnabled {
            let request = BadgesAPI.requestBadgesForUser(self.username)
            // turn badges into accomplishments
            let accomplishmentsTab = self.environment.networkManager.streamForRequest(request)
                .map { badges -> [Accomplishment] in
                    return badges.value.map { badge in
                        return Accomplishment(badge: badge, networkManager: self.environment.networkManager)
                    }
                }
                .map {accomplishments -> TabItem? in
                    return self.tabWithAccomplishments(accomplishments)
            }
            return joinStreams([accomplishmentsTab]).map { $0.flatMap { $0 }}
        }
        else {
            return Stream(value: [])
        }
    }()


    private func tabWithAccomplishments(accomplishments: [Accomplishment]) -> TabItem? {
        // turn accomplishments into the accomplishments tab
        if accomplishments.count > 0 {
            let view = AccomplishmentsView(accomplishments: accomplishments) {[weak self] in
                if let owner = self {
                    owner.delegate?.presenter(owner, choseShareURL:$0.shareURL)
                }
            }
            return TabItem(
                name: Strings.Accomplishments.title,
                view: view,
                identifier: UserProfileNetworkPresenter.AccomplishmentsTabIdentifier
            )
        }
        else {
            return nil
        }
    }
}