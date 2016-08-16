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
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXSessionEndedNotification) { (_, observer, _) in
            observer.clearFeed()
        }
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXSessionStartedNotification) { (notification, observer, _) -> Void in
            if let userDetails = notification.userInfo?[OEXSessionStartedUserDetailsKey] as? OEXUserDetails {
                observer.setupFeedWithUserDetails(userDetails)
            }
        }
    }
    
    private func clearFeed() {
        let feed = Feed<UserPreference?> { stream in
            stream.removeAllBackings()
            stream.send(Success(nil))
        }
        
        preferencesFeed.backWithFeed(feed)
        preferencesFeed.refresh()
    }
    
    private func setupFeedWithUserDetails(userDetails: OEXUserDetails) {
        guard let username = userDetails.username else { return }
        let feed = freshFeedWithUsername(username)
        preferencesFeed.backWithFeed(feed.map{x in x})
        preferencesFeed.refresh()
    }
    
    private func freshFeedWithUsername(username: String) -> Feed<UserPreference> {
        let request = UserPreferenceAPI.preferenceRequest(username)
        return Feed(request: request, manager: networkManager, persistResponse: true)
    }
    
}
