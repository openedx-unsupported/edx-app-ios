//
//  NetworkManagerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import XCTest

import edX

class NetworkManagerTests: XCTestCase {
    class AuthProvider : NSObject, AuthorizationHeaderProvider {
        var authorizationHeaders : [String:String] {
            return ["FakeHeader": "TestValue"]
        }
    }
    
    let authProvider = AuthProvider()
    let baseURL = NSURL(string:"http://example.com")!
    let cache = MockResponseCache()
    
    override func tearDown() {
        super.tearDown()
        cache.clear()
    }
    
    func testGetConstruction() {
        TestEnvironmentBuilder.test()
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: baseURL, cache : cache)
        let apiRequest = NetworkRequest(
            method: HTTPMethod.GET,
            path: "/something",
            requiresAuth: true,
            body: RequestBody.DataBody(data: "test".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, contentType: "edx/content"),
            query: ["a" : JSON("b"), "c":JSON("d")],
            deserializer : .DataResponse({ (response, data) -> Result<Void> in
                XCTFail("Shouldn't send request")
                return Failure(nil)
            })
        )
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.URL!.absoluteString, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.allHTTPHeaderFields!["Content-Type"]!, "edx/content")
            XCTAssertEqual(r.allHTTPHeaderFields!["FakeHeader"]!, "TestValue")
            XCTAssertEqual(r.HTTPMethod!, "GET")
        }
    }
    
    func testPostConstruction() {
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: baseURL, cache : cache)
        let sampleJSON = JSON([
            "Some field" : true,
            "Some other field" : ["a", "b"]
            ])
        let apiRequest = NetworkRequest(
            method: HTTPMethod.POST,
            path: "/something",
            requiresAuth: true,
            body: RequestBody.JSONBody(sampleJSON),
            query: ["a" : JSON("b"), "c":JSON("d")],
            deserializer : .DataResponse({ (response, data) -> Result<Void> in
                XCTFail("Shouldn't send request")
                return Failure(nil)
            })
        )
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.URL!.absoluteString, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.HTTPMethod!, "POST")
            XCTAssertEqual(r.allHTTPHeaderFields!["Content-Type"], "application/json")
            XCTAssertEqual(r.allHTTPHeaderFields!["FakeHeader"], "TestValue")
            let foundJSON = JSON(data : r.HTTPBody!)
            XCTAssertEqual(foundJSON, sampleJSON)
        }
    }
    
    // When running tests, we don't want network requests to actually work
    func testNetworkNotLive() {
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: NSURL(string:"https://google.com")!, cache : cache)
    
        let apiRequest = NetworkRequest(method: HTTPMethod.GET, path: "/", deserializer : .DataResponse({_ -> Result<NSObject> in
            XCTFail("Shouldn't receive data")
            return Failure(nil)
        }))
        // make sure this is a valid request
        AssertSuccess(manager.URLRequestWithRequest(apiRequest))
        
        let expectation = expectationWithDescription("Request dispatched")
        manager.taskForRequest(apiRequest) { result in
            XCTAssertNil(result.data)
            expectation.fulfill()
        }
        self.waitForExpectations()
    }
    
    func requestEnvironment() -> (MockNetworkManager, NetworkRequest<NSData>, NSURLRequest) {
        let manager = MockNetworkManager(authorizationHeaderProvider: authProvider, baseURL: NSURL(string:"http://example.com")!)
        let request = NetworkRequest<NSData> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .DataResponse({(_, data) in Success(data)}))
        let URLRequest = manager.URLRequestWithRequest(request).value!
        return (manager, request, URLRequest)
    }
    
    func testStreamCacheHit() {
        // Tests that if a request is in cache, we will send it and then the actual value from the network
        
        let (manager, request, URLRequest) = requestEnvironment()
        let response = NSHTTPURLResponse(URL: URLRequest.URL!, statusCode: 200, HTTPVersion: nil, headerFields: [:])!
        let originalData = "original".dataUsingEncoding(NSUTF8StringEncoding)!
        // first warm the cache
        let cacheExpectation = expectationWithDescription("Cache Store Completed")
        manager.responseCache.setCacheResponse(response, withData: originalData, forRequest: URLRequest, completion: {
            cacheExpectation.fulfill()
        })
        waitForExpectations()
        
        // make a request
        let networkData = "network".dataUsingEncoding(NSUTF8StringEncoding)!
        manager.interceptWhenMatching({_ -> Bool in return true },
            afterDelay : 0.1,
            withResponse: {_ in
            return NetworkResult(request: URLRequest, response: response, data: networkData, baseData: networkData, error: nil)
            }
        )
        
        // save the results
        let results = MutableBox<[NSData]>([])
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectationWithDescription("Request loaded from cache and regular")
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            stream.listen(owner, action: {
                var found = results.value
                found.append($0.value!)
                results.value = found
                if found.count == 2 {
                    loadedExpectation.fulfill()
                }
            })
            waitForExpectations()
        }

        XCTAssertEqual(results.value, [originalData, networkData])
    }
    
    func testCacheNotFilledRequestError() {
        // Test that the cache doesn't get an entry when the underlying request fails (e.g. network failure, not a 404
        
        let (manager, request, URLRequest) = requestEnvironment()
        manager.interceptWhenMatching({_ -> Bool in return true },
            withResponse: {_ in
                return NetworkResult<NSData>(request: URLRequest, response: nil, data: nil, baseData: nil, error: NSError.oex_unknownError())
            }
        )
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectationWithDescription("Request finished")

        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            stream.listen(owner) {_ in
                loadedExpectation.fulfill()
            }
            waitForExpectations()
        }
        
        XCTAssertTrue(cache.isEmpty, "Requests with no response shouldn't enter cache")
    }
    
    func testStreamSettlesInactive() {
        let (manager, request, _) = requestEnvironment()
        let stream = manager.streamForRequest(request)
        let expectation = expectationWithDescription("stream settles")
        stream.listen(self) {[weak stream] result in
            if !(stream?.active ?? false) {
                expectation.fulfill()
            }
        }
        waitForExpectations()
        XCTAssertFalse(stream.active)
        XCTAssertNotNil(stream.error)
    }
    
    func testCacheFilledRequestSuccess() {
        // Test that the cache gets an entry when the underlying request succeeds (e.g. network failure, not a 404
        
        let (manager, request, URLRequest) = requestEnvironment()
        let testData = "testData".dataUsingEncoding(NSUTF8StringEncoding)!
        let headers = ["a" : "b"]
        let response = NSHTTPURLResponse(URL: URLRequest.URL!, statusCode: 404, HTTPVersion: nil, headerFields: headers)!
        manager.interceptWhenMatching({_ -> Bool in return true },
            withResponse: {_ in
                return NetworkResult<NSData>(request: URLRequest, response: response, data: testData, baseData: testData, error: nil)
            }
        )
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectationWithDescription("Request finished")
        
        stream.listenOnce(self) {_ in
            loadedExpectation.fulfill()
        }
        waitForExpectations()
        
        let cacheExpectation = expectationWithDescription("Cache Load finished")
        manager.responseCache.fetchCacheEntryWithRequest(URLRequest) {
            XCTAssertEqual($0!.data!, testData)
            XCTAssertEqual($0!.statusCode, response.statusCode)
            XCTAssertEqual($0!.headers, headers)
            cacheExpectation.fulfill()
        }
        waitForExpectations()
    }
    
    func checkJSONInterceptionWithStubResponse(stubResponse : OHHTTPStubsResponse, verifier : Result<JSON> -> Void) {
        
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: NSURL(string:"http://example.com")!, cache : MockResponseCache())
        let request = NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .JSONResponse({(_, json) in Success(json)}))
        
        manager.addJSONInterceptor {(response : NSHTTPURLResponse?, json : JSON) in
            if response?.statusCode ?? 0 == 401 {
                return Failure(NSError(domain: "{}", code: -100, userInfo: [:]))
            }
            else {
                return Success(json)
            }
        }
        
        let stub = OHHTTPStubs.stubRequestsPassingTest({ (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return stubResponse
        })
        
        let expectation = expectationWithDescription("Request Completes")
        let stream = manager.streamForRequest(request, autoCancel : false)
        
        stream.extendLifetimeUntilFirstResult {
            verifier($0)
            expectation.fulfill()
        }
        
        waitForExpectations()
        
        OHHTTPStubs.removeStub(stub)
    }
    
    func testJSONInterceptionSucceeds() {
        checkJSONInterceptionWithStubResponse(OHHTTPStubsResponse(data: "{}".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 401, headers: nil), verifier: {
            $0.ifFailure {
                XCTAssertEqual($0.code, -100)
            }
            XCTAssertTrue($0.value == nil)
        })
    }
    
    func testJSONInterceptionPassthrough() {
        checkJSONInterceptionWithStubResponse(OHHTTPStubsResponse(data: "{}".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 404, headers: nil), verifier: {
            XCTAssertTrue($0.value != nil)
        })
    }
    
}
