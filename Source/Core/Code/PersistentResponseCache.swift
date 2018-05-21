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
// Use @objc so that if we move this between modules again, any new cache entries
// will reference the same class
@objc(OEXResponseCacheEntry) open class ResponseCacheEntry : NSObject, NSCoding {
    open let data : Data?
    open let headers : [String:String]
    open let statusCode : Int
    open let URL : Foundation.URL?
    open let creationDate : Date
    
    public convenience init(data : Data?, response : HTTPURLResponse) {
        self.init(data : data, headers : response.allHeaderFields as? [String:String] ?? [:], statusCode : response.statusCode, URL : response.url)
    }
    
    required public init?(coder : NSCoder) {
        data = coder.decodeObject(forKey: "data") as? Data
        headers = coder.decodeObject(forKey: "headers") as? [String:String] ?? [:]
        statusCode = coder.decodeInteger(forKey: "statusCode")
        URL = coder.decodeObject(forKey: "URL") as? Foundation.URL
        creationDate = (coder.decodeObject(forKey: "creationDate") as? Date) ?? Date.distantPast
    }
    
    fileprivate init(data : Data?, headers : [String:String], statusCode : Int, URL : Foundation.URL?) {
        self.data = data
        self.headers = headers
        self.statusCode = statusCode
        self.URL = URL
        self.creationDate = Date()
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(statusCode, forKey: "statusCode")
        aCoder.encode(data, forKey: "data")
        aCoder.encode(headers, forKey: "headers")
        aCoder.encode(URL, forKey: "URL")
        aCoder.encode(creationDate, forKey: "creationDate")
    }
    
    var response : HTTPURLResponse? {
        return URL.flatMap {
            return HTTPURLResponse(url: $0, statusCode: statusCode, httpVersion: nil, headerFields: headers)
        }
    }
}

public func responseCacheKeyForRequest(_ request : URLRequest) -> String? {
    if let urlString = request.url?.absoluteString,
        let method = request.httpMethod {
        return "\(urlString)_\(method)"
    }
    return nil
}


@objc public protocol ResponseCache : NSObjectProtocol {
    func fetchCacheEntryWithRequest(_ request : URLRequest, completion : @escaping (ResponseCacheEntry?) -> Void)
    func setCacheResponse(_ response : HTTPURLResponse, withData data : Data?, forRequest request : URLRequest, completion : (() -> Void)?)
}

@objc public protocol PathProvider {
    func pathForRequestKey(_ key: String?) -> URL?
}

open class PersistentResponseCache : NSObject, ResponseCache, NSKeyedUnarchiverDelegate {
    
    // We need a valid class that implements NSCoding to return in case unarchiving fails
    // because it can't find the class to unarchive.
    // Since it has no properties, it should work no matter what type is used
    // This will lose the cache entry when we try to cast to an actual cache entry type
    // but it's better than crashing
    @objc(_TtCC7edXCore23PersistentResponseCacheP33_29F7229A2B5F3B6F93C70C950BB0300319DummyCodeableObject)fileprivate class DummyCodeableObject: NSObject, NSCoding {
        @objc required init?(coder aDecoder: NSCoder) {
            return nil
        }
        
        @objc fileprivate func encode(with aCoder: NSCoder) {
            // do nothing
        }
    }
    
    fileprivate let queue : DispatchQueue
    fileprivate let pathProvider : PathProvider
    
    public init(provider : PathProvider) {
        queue = DispatchQueue(label: "org.edx.request-cache", attributes: [])
        self.pathProvider = provider
    }
    
    // When you move a class between modules it gets a different class name from the perspective of
    // unarchiving. This catches that case and reroutes the unarchiver to the correct class
    open func unarchiver(_ unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass? {
        if name.contains("Entry") {
            return ResponseCacheEntry.classForKeyedUnarchiver()
        }
        
        return DummyCodeableObject.classForKeyedUnarchiver()
    }
    
    fileprivate func unarchiveEntryWithData(_ data : Data) -> ResponseCacheEntry? {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        unarchiver.delegate = self
        let result = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? ResponseCacheEntry
        return result
    }
    
    public func fetchCacheEntryWithRequest(_ request: URLRequest, completion: @escaping (ResponseCacheEntry?) -> Void) {
        let path = self.pathProvider.pathForRequestKey(responseCacheKeyForRequest(request))
        queue.async {
            if let path = path,
                let data = try? Data(contentsOf: path, options: NSData.ReadingOptions()),
                let entry = self.unarchiveEntryWithData(data) {
                DispatchQueue.main.async {
                    completion(entry)
                }
            }
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            
        }
    }
    
    open func setCacheResponse(_ response : HTTPURLResponse, withData data : Data?, forRequest request : URLRequest, completion : (() -> Void)? = nil) {
        let entry = ResponseCacheEntry(data: data, response: response)
        let path = self.pathProvider.pathForRequestKey(responseCacheKeyForRequest(request))
        queue.async {
            let archive = NSKeyedArchiver.archivedData(withRootObject: entry)
            if let path = path {
                try? archive.write(to: path, options: [.atomic])
                DispatchQueue.main.async {
                    completion?()
                }
            }
            else {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
}
