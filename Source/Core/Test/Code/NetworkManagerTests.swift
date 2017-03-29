//
//  NetworkManagerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit
import XCTest

import edXCore

class NetworkManagerTests: XCTestCase {
    class AuthProvider : NSObject, AuthorizationHeaderProvider {
        var authorizationHeaders : [String:String] {
            return ["FakeHeader": "TestValue"]
        }
    }
    
    let authProvider = AuthProvider()
    let baseURL = URL(string:"http://example.com")!
    let cache = MockResponseCache()
    
    override func tearDown() {
        super.tearDown()
        cache.clear()
    }
    
    func testGetConstruction() {
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: baseURL, cache : cache)
        let apiRequest = NetworkRequest(
            method: HTTPMethod.GET,
            path: "/something",
            requiresAuth: true,
            body: RequestBody.DataBody(data: "test".dataUsingEncoding(String.Encoding.utf8, allowLossyConversion: false)!, contentType: "edx/content"),
            query: ["a" : JSON("b"), "c":JSON("d")],
            deserializer : .DataResponse({ (response, data) -> Result<Void> in
                XCTFail("Shouldn't send request")
                return .Failure(NetworkManager.unknownError)
            })
        )
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.URL!.absoluteString, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.allHTTPHeaderFields!["Content-Type"]!, "edx/content")
            XCTAssertEqual(r.allHTTPHeaderFields!["FakeHeader"]!, "TestValue")
            XCTAssertEqual(r.HTTPMethod!, "GET")
        }
    }
    
    func testJSONPostConstruction() {
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
                return .Failure(NetworkManager.unknownError)
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
    
    func testFormEncodingPostConstruction() {
        let manager = NetworkManager(authorizationHeaderProvider: authProvider, baseURL: baseURL, cache : cache)
        let fields = [
            "Some field" : "true",
            "Some other field" : "some value"
        ]
        let apiRequest = NetworkRequest(
            method: HTTPMethod.POST,
            path: "/something",
            requiresAuth: true,
            body: RequestBody.FormEncoded(fields),
            query: ["a" : JSON("b"), "c":JSON("d")],
            deserializer : .DataResponse({ (response, data) -> Result<Void> in
                XCTFail("Shouldn't send request")
                return .Failure(NetworkManager.unknownError)
            })
        )
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.URL!.absoluteString, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.HTTPMethod!, "POST")
            XCTAssertEqual(r.allHTTPHeaderFields!["Content-Type"], "application/x-www-form-urlencoded")
            XCTAssertEqual(r.allHTTPHeaderFields!["FakeHeader"], "TestValue")
            
            // Hackily extract form encoded fields
            let foundBody = String(data : r.HTTPBody!, encoding: NSUTF8StringEncoding)
            let items = foundBody?.componentsSeparatedByString("&") ?? []
            let pairs = items.map { return $0.componentsSeparatedByString("=") }
            
            // Sort since the fields are in arbitrary order
            let sortedPairs = pairs.sort({ return $0.first < $1.first })
            print("pairs are \(sortedPairs)")
            XCTAssertEqual(sortedPairs, [["Some%20field", "true"], ["Some%20other%20field", "some%20value"]])
        }
    }
    
    func requestEnvironment() -> (MockNetworkManager, NetworkRequest<NSData>, NSURLRequest) {
        let manager = MockNetworkManager(authorizationHeaderProvider: authProvider, baseURL: URL(string:"http://example.com")!)
        let request = NetworkRequest<Data> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .DataResponse({(_, data) in .Success(data)}))
        let URLRequest = manager.URLRequestWithRequest(request).value!
        return (manager, request, URLRequest)
    }
    
    func testStreamCacheHit() {
        // Tests that if a request is in cache, we will send it and then the actual value from the network
        
        let (manager, request, URLRequest) = requestEnvironment()
        let response = HTTPURLResponse(URL: URLRequest.URL!, statusCode: 200, HTTPVersion: nil, headerFields: [:])!
        let originalData = "original".data(using: String.Encoding.utf8)!
        // first warm the cache
        let cacheExpectation = expectation(description: "Cache Store Completed")
        manager.responseCache.setCacheResponse(response, withData: originalData, forRequest: URLRequest, completion: {
            cacheExpectation.fulfill()
        })
        waitForExpectations()
        
        // make a request
        let networkData = "network".data(using: String.Encoding.utf8)!
        manager.interceptWhenMatching({_ -> Bool in return true },
                                      afterDelay : 0.1,
                                      withResponse: {_ in
                                        return NetworkResult(request: URLRequest, response: response, data: networkData, baseData: networkData, error: nil)
            }
        )
        
        // save the results
        let results = MutableBox<[Data]>([])
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectation(description: "Request loaded from cache and regular")
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
                                        return NetworkResult<Data>(request: URLRequest, response: nil, data: nil, baseData: nil, error: NetworkManager.unknownError)
            }
        )
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectation(description: "Request finished")
        
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
        let expectation = self.expectation(description: "stream settles")
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
        let testData = "testData".data(using: String.Encoding.utf8)!
        let headers = ["a" : "b"]
        let response = HTTPURLResponse(URL: URLRequest.URL!, statusCode: 404, HTTPVersion: nil, headerFields: headers)!
        manager.interceptWhenMatching({_ -> Bool in return true },
                                      withResponse: {_ in
                                        return NetworkResult<Data>(request: URLRequest, response: response, data: testData, baseData: testData, error: nil)
            }
        )
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectation(description: "Request finished")
        
        stream.listenOnce(self) {_ in
            loadedExpectation.fulfill()
        }
        waitForExpectations()
        
        let cacheExpectation = expectation(description: "Cache Load finished")
        manager.responseCache.fetchCacheEntryWithRequest(URLRequest) {
            XCTAssertEqual($0!.data!, testData)
            XCTAssertEqual($0!.statusCode, response.statusCode)
            XCTAssertEqual($0!.headers, headers)
            cacheExpectation.fulfill()
        }
        waitForExpectations()
    }
    
    func testAuthenticationActionAuthenticateSuccess() {
        let manager = NetworkManager(authorizationHeaderProvider: nil, baseURL: baseURL, cache : cache)
        
        let expectation = self.expectation(description: "Request Completes")
        let request = NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .JSONResponse({(_, json) in .Success(json)}))
        
        let expectedStubResponse = simpleStubResponseBuilder(200, data: "{\"I Love\":\"Cake\"}")
        let stub200Response = OHHTTPStubs.stubRequestsPassingTest({ (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return expectedStubResponse
        })
        
        let initialStubResponse = simpleStubResponseBuilder(401, data: "{\"error_code\":\"token_expired\"}")
        let stub401Response = OHHTTPStubs.stubRequestsPassingTest({ (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return initialStubResponse
        })
        
        
        manager.authenticator = { (response, data) -> AuthenticationAction in
            if response!.statusCode == 401 {
                return AuthenticationAction.Authenticate({ (networkManager, completion) in
                    OHHTTPStubs.removeStub(stub401Response)
                    return completion(_success: true)
                })}
            else {
                OHHTTPStubs.removeStub(stub200Response)
                return AuthenticationAction.Proceed
            }
        }
        
        manager.taskForRequest(request) { (response) in
            XCTAssertEqual(response.response?.statusCode, 200)
            XCTAssertEqual(response.data?.rawString(), "{\n  \"I Love\" : \"Cake\"\n}")
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func testAuthenticationActionAuthenticateFailure() {
        let manager = NetworkManager(authorizationHeaderProvider: nil, baseURL: baseURL, cache : cache)
       
        let expectation = self.expectation(description: "Request Completes")
        let request = NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .JSONResponse({(_, json) in .Success(json)}))
        
        let expectedStubResponse = simpleStubResponseBuilder(401, data: "{\"error_code\":\"token_expired\"}")
        let stub401Response = OHHTTPStubs.stubRequestsPassingTest({ (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return expectedStubResponse
        })
        
        manager.authenticator = { (response, data) -> AuthenticationAction in
            return AuthenticationAction.Authenticate({ (networkManager, completion) in
                OHHTTPStubs.removeStub(stub401Response)
                return completion(_success: false)
            })
        }
        
        manager.taskForRequest(request) { (response) in
            XCTAssertEqual(response.response?.statusCode, 401)
            XCTAssertEqual(response.data, nil)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func simpleStubResponseBuilder(_ statusCode: Int32, data: String) -> OHHTTPStubsResponse{
        return OHHTTPStubsResponse(
            data: data.dataUsingEncoding(NSUTF8StringEncoding)!,
            statusCode: statusCode,
            headers: nil)
    }
}
