//
//  PersistentResponseCacheTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import XCTest
import edXCore

class PersistentResponseCacheTests: XCTestCase {
    
    class Provider : NSObject, PathProvider {
        let username : String
        let basePath: URL
        init(username : String, basePath: URL) {
            self.username = username
            self.basePath = basePath
        }
        
        func pathForRequestKey(_ key: String?) -> URL? {
            return key.map {
                let path = basePath
                    .appendingPathComponent(self.username, isDirectory: true)
                try! FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: [:])

                return path.appendingPathComponent($0.oex_md5)
            }
        }
    }

    var username: String!
    var basePath: URL!
    
    override func setUp() {
        super.setUp()

        basePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("persistent-cache-tests", isDirectory: true)
        username = UUID().uuidString
    }
    
    override func tearDown() {
        super.tearDown()

        do {
            try FileManager.default.removeItem(at: basePath)
        }
        catch {
            XCTFail()
        }
    }
    
    func testStoreLoad() {
        let cache = PersistentResponseCache(provider : Provider(username: username, basePath: basePath))
        let storeExpectation = expectation(description: "Cache stored")
        let request = URLRequest(url: URL(string: "http://example.com")!)
        let statusCode = 200
        let headers = ["Something" : "Value"]
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
        let data = "test data".data(using: String.Encoding.utf8)
        
        cache.setCacheResponse(response, withData: data, forRequest: request) {
            storeExpectation.fulfill()
        }
        waitForExpectations()
        
        let loadExpectation = expectation(description: "Cache loaded")
        cache.fetchCacheEntryWithRequest(request) {entry in
            loadExpectation.fulfill()
            XCTAssertEqual(entry!.data!, data!)
            XCTAssertEqual(entry!.statusCode, statusCode)
            XCTAssertEqual(entry!.headers, headers)
        }
        waitForExpectations()
    }
    
    func testDifferentMethods() {
        // Store different data with the same URL but different HTTP methods
        // and make sure we get the different data out
        let cache = PersistentResponseCache(provider : Provider(username: username, basePath: basePath))
        let getRequest = URLRequest(url: URL(string: "http://example.com")!)
        let response = HTTPURLResponse(url: getRequest.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
        
        let getData = "test data".data(using: String.Encoding.utf8)!
        let getStoreExpectation = expectation(description: "Cache stored GET")
        cache.setCacheResponse(response, withData: getData, forRequest: getRequest) {
            getStoreExpectation.fulfill()
        }
        waitForExpectations()
        
        let postStoreExpectation = expectation(description: "Cache stored POST")
        let postData = "test data".data(using: String.Encoding.utf8)!
        let postRequest = (getRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        postRequest.httpMethod = "POST"
        
        cache.setCacheResponse(response, withData: postData, forRequest: postRequest as URLRequest) {
            postStoreExpectation.fulfill()
        }
        waitForExpectations()
        
        let getLoadExpectation = expectation(description: "Cache loaded GET")
        cache.fetchCacheEntryWithRequest(getRequest) {
            XCTAssertEqual($0!.data!, getData)
            getLoadExpectation.fulfill()
        }
        waitForExpectations()
        
        let postLoadExpectation = expectation(description: "Cache loaded POST")
        cache.fetchCacheEntryWithRequest(postRequest as URLRequest) {
            XCTAssertEqual($0!.data!, postData)
            postLoadExpectation.fulfill()
        }
        waitForExpectations()
    }
    
    func testMiss() {
        let cache = PersistentResponseCache(provider : Provider(username: username, basePath: basePath))
        let request = URLRequest(url: URL(string: "http://example.com")!)
        // Just shove something in the cache to make sure we don't get that
        let storeExpectation = expectation(description: "Cache stored")
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
        cache.setCacheResponse(response, withData: nil, forRequest: request) {
            storeExpectation.fulfill()
        }
        waitForExpectations()
        
        let loadExpectation = expectation(description: "Cache loaded")
        let otherRequest = URLRequest(url: URL(string : "http://edx.org")!)
        cache.fetchCacheEntryWithRequest(otherRequest) {
            XCTAssertNil($0)
            loadExpectation.fulfill()
        }
        waitForExpectations()
    }


    // Basic class that implements NSCoding
    class CodeableObject : NSObject, NSCoding {
        override init() {
            super.init()
        }

        required init?(coder aDecoder: NSCoder) {
        }

        func encode(with aCoder: NSCoder) {
            // no representation
        }
    }

    // Since we use NSCoding to save cache entries, it's not super robust against
    // refactoring like class name changes or moving classes between modules.
    // This test saves a cache file with a class
    // that only exists temporarily and makes sure we don't crash if the class is gone.
    func testInvalidObjectNoCrash() {

        let url = "http://example.com/url"
        let request = URLRequest(url: URL(string: url)!)
        let key = responseCacheKeyForRequest(request)
        let provider = Provider(username: username, basePath: basePath)
        let path = provider.pathForRequestKey(key)

        let klass: AnyClass = objc_allocateClassPair(CodeableObject.self, "FakeClass", 0)
        objc_registerClassPair(klass)
        autoreleasepool {
            let object = OEXMetaClassHelpers.instance(ofClassNamed: "FakeClass")
            NSKeyedArchiver.archiveRootObject(object!, toFile: path!.path)
        }
        objc_disposeClassPair(klass)

        let cache = PersistentResponseCache(provider: provider)

        let expectation = self.expectation(description: "cache loads")
        cache.fetchCacheEntryWithRequest(request) { (entry) in
            XCTAssertNil(entry)
            expectation.fulfill()
        }
        waitForExpectations()
    }

    // Since we use NSCoding to save cache entries, it's not super robust against
    // refactoring like class name changes or moving classes between modules.
    // This test saves a cache file with a variant
    // of the entry class that only exists temporarily and makes sure we still get
    // a proper cache entry. This is a proxy for trying to unarchive the same class, but moved
    // to a different module which is hard to fake.
    func testCacheEntryClassRenamed() {
        let url = "http://example.com/url"
        let request = URLRequest(url: URL(string: url)!)
        let key = responseCacheKeyForRequest(request)
        let provider = Provider(username: username, basePath: basePath)
        let path = provider.pathForRequestKey(key)

        let klass: AnyClass = objc_allocateClassPair(ResponseCacheEntry.self, "FakeEntryClass", 0)
        objc_registerClassPair(klass)
        autoreleasepool {
            let entry = ResponseCacheEntry(data: "test".data(using: String.Encoding.utf8), response: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
            object_setClass(entry, klass)
            NSKeyedArchiver.archiveRootObject(entry, toFile: path!.path)
        }
        objc_disposeClassPair(klass)

        let cache = PersistentResponseCache(provider: provider)

        let expectation = self.expectation(description: "cache loads")
        cache.fetchCacheEntryWithRequest(request) { (entry) in
            XCTAssertEqual(entry?.statusCode, 200)
            XCTAssertEqual(entry?.URL, request.url)
            XCTAssertEqual(entry?.data, "test".data(using: String.Encoding.utf8))
            expectation.fulfill()
        }
        waitForExpectations()
    }

}
