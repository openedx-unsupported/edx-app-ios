//
//  MockResponseCache.swift
//  edX
//
//  Created by Akiva Leffert on 6/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edXCore

class MockResponseCache: NSObject, ResponseCache {
    private var backing : [String: ResponseCacheEntry] = [:]
    
    func fetchCacheEntryWithRequest(request: NSURLRequest, completion: ResponseCacheEntry? -> Void) {
        let key = responseCacheKeyForRequest(request)
        completion(key.flatMap{ backing[$0] })
    }
    
    func setCacheResponse(response: NSHTTPURLResponse, withData data: NSData?, forRequest request: NSURLRequest, completion: (Void -> Void)?) {
        if let key = responseCacheKeyForRequest(request) {
            backing[key] = ResponseCacheEntry(data : data, response : response)
        }
        completion?()
    }
    
    func clear() {
        backing = [:]
    }
    
    var isEmpty : Bool {
        return backing.count == 0
    }
}
