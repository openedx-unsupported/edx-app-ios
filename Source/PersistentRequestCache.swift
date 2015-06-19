//
//  PersistentRequestCache.swift
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol UsernameProvider {
    var currentUsername : String? { get }
}

public class PersistentRequestCache {
    public class Entry : NSObject, NSCoding {
        public let data : NSData?
        public let headers : [String:String]
        public let statusCode : Int
        
        private convenience init(data : NSData?, response : NSHTTPURLResponse) {
            self.init(data : data, headers : response.allHeaderFields as? [String:String] ?? [:], statusCode : response.statusCode)
        }
        
        required public init(coder : NSCoder) {
            data = coder.decodeObjectForKey("data") as? NSData
            headers = coder.decodeObjectForKey("headers") as? [String:String] ?? [:]
            statusCode = coder.decodeIntegerForKey("statusCode")
        }
        
        private init(data : NSData?, headers : [String:String], statusCode : Int) {
            self.data = data
            self.headers = headers
            self.statusCode = statusCode
        }
        
        public func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeInteger(statusCode, forKey: "statusCode")
            aCoder.encodeObject(data, forKey: "data")
            aCoder.encodeObject(headers, forKey: "headers")
        }
    }
    
    private let queue : dispatch_queue_t
    private let provider : UsernameProvider
    
    public init(provider : UsernameProvider) {
        queue = dispatch_queue_create("org.edx.request-cache", DISPATCH_QUEUE_SERIAL)
        self.provider = provider
    }
    
    private func keyForRequest(request : NSURLRequest) -> String? {
        if let urlString = request.URL?.absoluteString,
            method = request.HTTPMethod {
            return "\(urlString)_\(method)"
        }
        return nil
    }
    
    public func fetchCacheEntryWithRequest(request : NSURLRequest, completion : Entry? -> Void) {
        let path = OEXFileUtility.fileURLForRequestKey(keyForRequest(request), username: self.provider.currentUsername)
        dispatch_async(queue) {
            if let path = path,
                data = NSData(contentsOfURL: path, options: NSDataReadingOptions(), error: nil),
                entry = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Entry {
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
        let entry = Entry(data: data, response: response)
        let path = OEXFileUtility.fileURLForRequestKey(keyForRequest(request), username: self.provider.currentUsername)
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
