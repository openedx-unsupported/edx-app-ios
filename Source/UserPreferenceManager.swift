//
//  UserPreferenceManager.swift
//  edX
//
//  Created by Kevin Kim on 7/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public class UserPreferenceManager : NSObject {
    
    private let networkManager : NetworkManager
    private let preferencesFeed = BackedFeed<UserPreference?>()
    
    public init(networkManager : NetworkManager) {
        self.networkManager = networkManager
        
        super.init()
        
        addObservers()
    }
    
    public var feed: BackedFeed<UserPreference?> {
        return preferencesFeed
    }
    
    private func addObservers() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) in
            observer.clearFeed()
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionStarted.rawValue) { (notification, observer, _) -> Void in
            if let userDetails = notification.userInfo?[OEXSessionStartedUserDetailsKey] as? OEXUserDetails {
                observer.setupFeedWithUserDetails(userDetails: userDetails)
            }
        }
    }
    
    private func clearFeed() {
        let feed = Feed<UserPreference?> { stream in
            stream.removeAllBackings()
            stream.send(Success(v: nil))
        }
        
        preferencesFeed.backWithFeed(feed: feed)
        preferencesFeed.refresh()
    }
    
    private func setupFeedWithUserDetails(userDetails: OEXUserDetails) {
        guard let username = userDetails.username else { return }
        let feed = freshFeedWithUsername(username: username)
        preferencesFeed.backWithFeed(feed: feed.map{x in x})
        preferencesFeed.refresh()
    }
    
    private func freshFeedWithUsername(username: String) -> Feed<UserPreference> {
        let request = UserPreferenceAPI.preferenceRequest(username: username)
        return Feed(request: request, manager: networkManager, persistResponse: true)
    }
    
}
