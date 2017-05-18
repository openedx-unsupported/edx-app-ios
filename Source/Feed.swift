//
//  Feed.swift
//  edX
//
//  Created by Michael Katz on 10/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public class Feed<A> : LifetimeTrackable {
    public let lifetimeToken = NSObject()
    
    fileprivate let backing = BackedStream<A>()
    private let refreshTrigger : (BackedStream<A>) -> Void
    
    public var output : OEXStream<A> {
        return backing
    }
    
    public init(refreshTrigger : @escaping (BackedStream<A>) -> Void) {
        self.refreshTrigger = refreshTrigger
    }
    
    public func refresh() {
        self.refreshTrigger(backing)
    }
    
    public func map<B>(f : @escaping (A) -> B) -> Feed<B> {
        let backing = BackedStream<A>()
        let result = Feed<B> { stream in
            self.refreshTrigger(backing)
            stream.backWithStream(backing.map(f))
        }
        return result
    }
}

public class BackedFeed<A> : Feed<A> {
    private var feed : Feed<A>?
    private var backingRemover : Removable?
    
    public var backingStream : BackedStream<A> {
        return self.backing
    }
    
    public init() {
        super.init {_ in } // we override refresh so we don't need this
    }
    
    public func backWithFeed(feed : Feed<A>) {
        self.removeBacking()
        
        self.feed = feed
        self.backingRemover = self.backing.addBackingStream(feed.backing)
    }
    
    public func removeBacking() {
        self.feed = nil
        self.backingRemover?.remove()
        self.backingRemover = nil
    }
    
    override public func refresh() {
        self.feed?.refresh()
    }
}

extension Feed {
    convenience init(request : NetworkRequest<A>, manager : NetworkManager, persistResponse: Bool = false) {
        self.init(refreshTrigger: {backing in
            backing.addBackingStream(manager.streamForRequest(request, persistResponse: persistResponse))
        })
    }
}
