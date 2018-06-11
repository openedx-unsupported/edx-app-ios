//
//  UserProfilePresenter.swift
//  edX
//
//  Created by Akiva Leffert on 4/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension Accomplishment {
    init(badge: BadgeAssertion, networkManager: NetworkManager) {
        let image = RemoteImageImpl(url: badge.imageURL, networkManager: networkManager, placeholder: nil, persist: false)
        self.init(image: image, title: badge.badgeClass.name, detail: badge.badgeClass.detail, date: badge.created, shareURL: badge.assertionURL as NSURL)
    }
}

protocol UserProfilePresenterDelegate : class {
    func presenter(presenter: UserProfilePresenter, choseShareURL url: NSURL)
}

typealias ProfileTabItem = (UIScrollView) -> TabItem

protocol UserProfilePresenter: class {

    var profileStream: OEXStream<UserProfile> { get }
    var tabStream: OEXStream<[ProfileTabItem]> { get }
    func refresh() -> Void

    var delegate: UserProfilePresenterDelegate? { get }
}

class UserProfileNetworkPresenter : NSObject, UserProfilePresenter {
    typealias Environment = OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXSessionProvider

    static let AccomplishmentsTabIdentifier = "AccomplishmentsTab"
    private let profileFeed: Feed<UserProfile>
    private let environment: Environment
    private let username: String

    var profileStream: OEXStream<UserProfile> {
        return profileFeed.output
    }

    weak var delegate: UserProfilePresenterDelegate?

    init(environment: Environment, username: String) {
        self.profileFeed = environment.dataManager.userProfileManager.feedForUser(username: username)
        self.environment = environment
        self.username = username

        super.init()

        self.refresh()
    }

    func refresh() {
        profileFeed.refresh()
    }

    private var canShareAccomplishments : Bool {
        return self.username == self.environment.session.currentUser?.username
    }

    lazy var tabStream: OEXStream<[ProfileTabItem]> = {
        if self.environment.config.badgesEnabled {
            // turn badges into accomplishments
            let networkManager = self.environment.networkManager
            let paginator = WrappedPaginator(networkManager: self.environment.networkManager) {
                BadgesAPI.requestBadgesForUser(self.username, page: $0).map {paginatedBadges in
                    // turn badges into accomplishments
                    return paginatedBadges.map {badges in
                        badges.map {badge in
                            return Accomplishment(badge: badge, networkManager: networkManager)
                        }
                    }
                }
            }
            paginator.loadMore()

            let sink = Sink<[Accomplishment]>()
            paginator.stream.listenOnce(self) {
                sink.send($0)
            }

            let accomplishmentsTab = sink.map {accomplishments -> ProfileTabItem? in
                    return self.tabWithAccomplishments(accomplishments: accomplishments, paginator: AnyPaginator(paginator))
            }
            return joinStreams([accomplishmentsTab]).map { $0.flatMap { $0 }}
        }
        else {
            return OEXStream(value: [])
        }
    }()


    private func tabWithAccomplishments(accomplishments: [Accomplishment], paginator: AnyPaginator<Accomplishment>) -> ProfileTabItem? {
        // turn accomplishments into the accomplishments tab
        if accomplishments.count > 0 {
            return {scrollView -> TabItem in
                let shareAction : (Accomplishment) -> Void = {[weak self] in
                    if let owner = self {
                        owner.delegate?.presenter(presenter: owner, choseShareURL:$0.shareURL)
                    }
                }
                let view = AccomplishmentsView(paginator: paginator, containingScrollView: scrollView, shareAction: self.canShareAccomplishments ? shareAction: nil)
                return TabItem(
                    name: Strings.Accomplishments.title,
                    view: view,
                    identifier: UserProfileNetworkPresenter.AccomplishmentsTabIdentifier
                )
            }
        }
        else {
            return nil
        }
    }

}
