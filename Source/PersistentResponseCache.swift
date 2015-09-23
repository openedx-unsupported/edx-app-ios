//
//  PersistentResponseCache.swift
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

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

@objc public protocol UsernameProvider {
    var currentUsername : String? { get }
}

@objc public class SessionUsernameProvider : NSObject, UsernameProvider {
    private let session : OEXSession
    public init(session : OEXSession) {
        self.session = session
    }
    
    public var currentUsername : String? {
        return self.session.currentUser?.username
    }
}

@objc public class PersistentResponseCache : NSObject, ResponseCache {
    
    private let queue : dispatch_queue_t
    private let provider : UsernameProvider
    
    public init(provider : UsernameProvider) {
        queue = dispatch_queue_create("org.edx.request-cache", DISPATCH_QUEUE_SERIAL)
        self.provider = provider
    }
    
    public func fetchCacheEntryWithRequest(request : NSURLRequest, completion : ResponseCacheEntry? -> Void) {
        let path = OEXFileUtility.fileURLForRequestKey(responseCacheKeyForRequest(request), username: self.provider.currentUsername)
        dispatch_async(queue) {
            if let path = path,
                data = try? NSData(contentsOfURL: path, options: NSDataReadingOptions()),
                entry = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ResponseCacheEntry {
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
        let path = OEXFileUtility.fileURLForRequestKey(responseCacheKeyForRequest(request), username: self.provider.currentUsername)
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
