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
        let basePath: NSURL
        init(username : String, basePath: NSURL) {
            self.username = username
            self.basePath = basePath
        }
        
        func pathForRequestKey(key: String?) -> NSURL? {
            return key.map {
                let path = basePath
                    .URLByAppendingPathComponent(self.username, isDirectory: true)
                try! NSFileManager.defaultManager().createDirectoryAtURL(path, withIntermediateDirectories: true, attributes: [:])

                return path.URLByAppendingPathComponent($0.oex_md5)
            }
        }
    }

    var username: String!
    var basePath: NSURL!
    
    override func setUp() {
        super.setUp()

        basePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("persistent-cache-tests", isDirectory: true)
        username = NSUUID().UUIDString
    }
    
    override func tearDown() {
        super.tearDown()

        do {
            try NSFileManager.defaultManager().removeItemAtURL(basePath)
        }
        catch {
            XCTFail()
        }
    }
    
    func testStoreLoad() {
        let cache = PersistentResponseCache(provider : Provider(username: username, basePath: basePath))
        let storeExpectation = expectationWithDescription("Cache stored")
        let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)
        let statusCode = 200
        let headers = ["Something" : "Value"]
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: statusCode, HTTPVersion: nil, headerFields: headers)!
        let data = "test data".dataUsingEncoding(NSUTF8StringEncoding)
        
        cache.setCacheResponse(response, withData: data, forRequest: request) {
            storeExpectation.fulfill()
        }
        waitForExpectations()
        
        let loadExpectation = expectationWithDescription("Cache loaded")
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
        let getRequest = NSURLRequest(URL: NSURL(string: "http://example.com")!)
        let response = NSHTTPURLResponse(URL: getRequest.URL!, statusCode: 200, HTTPVersion: nil, headerFields: [:])!
        
        let getData = "test data".dataUsingEncoding(NSUTF8StringEncoding)!
        let getStoreExpectation = expectationWithDescription("Cache stored GET")
        cache.setCacheResponse(response, withData: getData, forRequest: getRequest) {
            getStoreExpectation.fulfill()
        }
        waitForExpectations()
        
        let postStoreExpectation = expectationWithDescription("Cache stored POST")
        let postData = "test data".dataUsingEncoding(NSUTF8StringEncoding)!
        let postRequest = getRequest.mutableCopy() as! NSMutableURLRequest
        postRequest.HTTPMethod = "POST"
        
        cache.setCacheResponse(response, withData: postData, forRequest: postRequest) {
            postStoreExpectation.fulfill()
        }
        waitForExpectations()
        
        let getLoadExpectation = expectationWithDescription("Cache loaded GET")
        cache.fetchCacheEntryWithRequest(getRequest) {
            XCTAssertEqual($0!.data!, getData)
            getLoadExpectation.fulfill()
        }
        waitForExpectations()
        
        let postLoadExpectation = expectationWithDescription("Cache loaded POST")
        cache.fetchCacheEntryWithRequest(postRequest) {
            XCTAssertEqual($0!.data!, postData)
            postLoadExpectation.fulfill()
        }
        waitForExpectations()
    }
    
    func testMiss() {
        let cache = PersistentResponseCache(provider : Provider(username: username, basePath: basePath))
        let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)
        // Just shove something in the cache to make sure we don't get that
        let storeExpectation = expectationWithDescription("Cache stored")
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: nil, headerFields: [:])!
        cache.setCacheResponse(response, withData: nil, forRequest: request) {
            storeExpectation.fulfill()
        }
        waitForExpectations()
        
        let loadExpectation = expectationWithDescription("Cache loaded")
        let otherRequest = NSURLRequest(URL: NSURL(string : "http://edx.org")!)
        cache.fetchCacheEntryWithRequest(otherRequest) {
            XCTAssertNil($0)
            loadExpectation.fulfill()
        }
        waitForExpectations()
    }

}
