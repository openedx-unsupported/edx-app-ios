//
//  PersistentResponseCache.swift
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

// Be careful renaming this class or moving it between modules
// since we archive instances of it to disk using NSCoding
// which figures out how to inflate a class by looking it up by name.
// Note that different swift modules will result in different class names even if the
// class name string didn't change
// TODO: Migrate off of NSCoding and instead write JSON blobs
// It's less convenient, but as a format it's less tied to our code at a specific
// moment in time
public class ResponseCacheEntry : NSObject, NSCoding {
    public let data : NSData?
    public let headers : [String:String]
    public let statusCode : Int
    public let URL : NSURL?
    public let creationDate : NSDate
    
    public convenience init(data : NSData?, response : NSHTTPURLResponse) {
        self.init(data : data, headers : response.allHeaderFields as? [String:String] ?? [:], statusCode : response.statusCode, URL : response.URL)
    }
    
    required public init?(coder : NSCoder) {
        data = coder.decodeObjectForKey("data") as? NSData
        headers = coder.decodeObjectForKey("headers") as? [String:String] ?? [:]
        statusCode = coder.decodeIntegerForKey("statusCode")
        URL = coder.decodeObjectForKey("URL") as? NSURL
        creationDate = (coder.decodeObjectForKey("creationDate") as? NSDate) ?? NSDate.distantPast()
    }
    
    private init(data : NSData?, headers : [String:String], statusCode : Int, URL : NSURL?) {
        self.data = data
        self.headers = headers
        self.statusCode = statusCode
        self.URL = URL
        self.creationDate = NSDate()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(statusCode, forKey: "statusCode")
        aCoder.encodeObject(data, forKey: "data")
        aCoder.encodeObject(headers, forKey: "headers")
        aCoder.encodeObject(URL, forKey: "URL")
        aCoder.encodeObject(creationDate, forKey: "creationDate")
    }
    
    var response : NSHTTPURLResponse? {
        return URL.flatMap {
            return NSHTTPURLResponse(URL: $0, statusCode: statusCode, HTTPVersion: nil, headerFields: headers)
        }
    }
}

public func responseCacheKeyForRequest(request : NSURLRequest) -> String? {
    if let urlString = request.URL?.absoluteString,
        method = request.HTTPMethod {
            return "\(urlString)_\(method)"
    }
    return nil
}


@objc public protocol ResponseCache : NSObjectProtocol {
    func fetchCacheEntryWithRequest(request : NSURLRequest, completion : ResponseCacheEntry? -> Void)
    func setCacheResponse(response : NSHTTPURLResponse, withData data : NSData?, forRequest request : NSURLRequest, completion : (Void -> Void)?)
}

@objc public protocol PathProvider {
    func pathForRequestKey(key: String?) -> NSURL?
}

@objc public class PersistentResponseCache : NSObject, ResponseCache, NSKeyedUnarchiverDelegate {

    // We need a valid class that implements NSCoding to return in case unarchiving fails
    // because it can't find the class to unarchive.
    // Since it has no properties, it should work no matter what type is used
    // This will lose the cache entry when we try to cast to an actual cache entry type
    // but it's better than crashing
    private class DummyCodeableObject: NSObject, NSCoding {
        @objc required init?(coder aDecoder: NSCoder) {
            return nil
        }

        @objc private func encodeWithCoder(aCoder: NSCoder) {
            // do nothing
        }
    }
    
    private let queue : dispatch_queue_t
    private let pathProvider : PathProvider
    
    public init(provider : PathProvider) {
        queue = dispatch_queue_create("org.edx.request-cache", DISPATCH_QUEUE_SERIAL)
        self.pathProvider = provider
    }

    // When you move a class between modules it gets a different class name from the perspective of
    // unarchiving. This catches that case and reroutes the unarchiver to the correct class
    public func unarchiver(unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass? {
        if name.containsString("Entry") {
            return ResponseCacheEntry.classForKeyedUnarchiver()
        }

        return DummyCodeableObject.classForKeyedUnarchiver()
    }

    private func unarchiveEntryWithData(data : NSData) -> ResponseCacheEntry? {
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        unarchiver.delegate = self
        let result = unarchiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as? ResponseCacheEntry
        return result
    }
    
    public func fetchCacheEntryWithRequest(request : NSURLRequest, completion : ResponseCacheEntry? -> Void) {
        let path = self.pathProvider.pathForRequestKey(responseCacheKeyForRequest(request))
        dispatch_async(queue) {
            if let path = path,
                data = try? NSData(contentsOfURL: path, options: NSDataReadingOptions()),
                entry = self.unarchiveEntryWithData(data) {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(entry)
                    }
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(nil)
                }
            }
            
        }
    }
    
    public func setCacheResponse(response : NSHTTPURLResponse, withData data : NSData?, forRequest request : NSURLRequest, completion : (Void -> Void)? = nil) {
        let entry = ResponseCacheEntry(data: data, response: response)
        let path = self.pathProvider.pathForRequestKey(responseCacheKeyForRequest(request))
        dispatch_async(queue) {
            let archive = NSKeyedArchiver.archivedDataWithRootObject(entry)
            if let path = path {
                archive.writeToURL(path, atomically: true)
                dispatch_async(dispatch_get_main_queue()) {
                    completion?()
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    completion?()
                }
            }
        }
    }
}
