//
//  UserProfileManager.swift
//  edX
//
//  Created by Akiva Leffert on 10/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation


open class UserProfileManager : NSObject {
    
    private let networkManager : NetworkManager
    private let session: OEXSession
    private let currentUserFeed = BackedFeed<UserProfile>()
    private let currentUserUpdateStream = Sink<UserProfile>()
    private let cache = LiveObjectCache<Feed<UserProfile>>()
    
    public init(networkManager : NetworkManager, session : OEXSession) {
        self.networkManager = networkManager
        self.session = session
        
        super.init()
        
        self.currentUserFeed.backingStream.addBackingStream(currentUserUpdateStream)
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, owner, _) -> Void in
            owner.sessionChanged()
        }
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionStarted.rawValue) { (_, owner, _) -> Void in
            owner.sessionChanged()
        }
        self.sessionChanged()
    }
    
    open func feedForUser(username : String) -> Feed<UserProfile> {
        return self.cache.objectForKey(key: username) {
            let request = ProfileAPI.profileRequest(username: username)
            return Feed(request: request, manager: self.networkManager)
        }
    }
    
    private func sessionChanged() {
        if let username = self.session.currentUser?.username {
            self.currentUserFeed.backWithFeed(feed: self.feedForUser(username: username))
        }
        else {
            self.currentUserFeed.removeBacking()
            // clear the stream
            self.currentUserUpdateStream.send(NSError.oex_unknownError())
        }
        if self.session.currentUser == nil {
            self.cache.empty()
        }
    }
    
    // Feed that updates if the current user changes
    public func feedForCurrentUser() -> Feed<UserProfile> {
        return currentUserFeed
    }
    
    public func updateCurrentUserProfile(profile : UserProfile, handler : @escaping (Result<UserProfile>) -> Void) {
        let request = ProfileAPI.profileUpdateRequest(profile: profile)
        self.networkManager.taskForRequest(request) { result -> Void in
            if let data = result.data {
                self.currentUserUpdateStream.send(Success(v: data))
            }
            handler(result.data.toResult(result.error!))
        }
    }
}
