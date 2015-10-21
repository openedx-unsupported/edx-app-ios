//
//  Feed.swift
//  edX
//
//  Created by Michael Katz on 10/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

public class Feed<A> {
    
    private let backing = BackedStream<A>()
    private let refreshTrigger : BackedStream<A> -> Void
    
    public var output : Stream<A> {
        return backing
    }
    
    init(refreshTrigger : BackedStream<A> -> Void) {
        self.refreshTrigger = refreshTrigger
    }
    
    public func refresh() {
        self.refreshTrigger(backing)
    }
}

extension Feed {
    convenience init(request : NetworkRequest<A>, manager : NetworkManager) {
        self.init(refreshTrigger: {backing in
            backing.backWithStream(manager.streamForRequest(request))
        })
    }
}