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
@testable import edX


class NetworkManagerTests: XCTestCase {
    class AuthProvider : NSObject, AuthorizationHeaderProvider, SessionDataProvider {
        var authorizationHeaders : [String:String] {
            return ["FakeHeader": "TestValue"]
        }
        
        var isUserLoggedIn: Bool {
            return true
        }
        
        var tokenExpiryDuration: NSNumber? {
            return 1
        }
        
        var tokenExpiryDate: Date? {
            return Date()
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
        let manager = NetworkManager(authorizationDataProvider: authProvider, baseURL: baseURL, cache : cache)
        let apiRequest = NetworkRequest(
            method: HTTPMethod.GET,
            path: "/something",
            requiresAuth: true,
            body: RequestBody.dataBody(data: "test".data(using: String.Encoding.utf8, allowLossyConversion: false)!, contentType: "edx/content"),
            query: ["a" : JSON("b"), "c":JSON("d")],
            deserializer : .dataResponse({ (response, data) -> Result<Void> in
                XCTFail("Shouldn't send request")
                return .failure(NetworkManager.unknownError)
            })
        )
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.url!.absoluteString, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.allHTTPHeaderFields!["Content-Type"]!, "edx/content")
            XCTAssertEqual(r.allHTTPHeaderFields!["FakeHeader"]!, "TestValue")
            XCTAssertEqual(r.httpMethod!, "GET")
        }
    }
    
    func testJSONPostConstruction() {
        let manager = NetworkManager(authorizationDataProvider: authProvider, baseURL: baseURL, cache : cache)
        let sampleJSON = JSON([
            "Some field" : true,
            "Some other field" : ["a", "b"]
            ] as [String : Any])
        let apiRequest = NetworkRequest(
            method: HTTPMethod.POST,
            path: "/something",
            requiresAuth: true,
            body: RequestBody.jsonBody(sampleJSON),
            query: ["a" : JSON("b"), "c":JSON("d")],
            deserializer : .dataResponse({ (response, data) -> Result<Void> in
                XCTFail("Shouldn't send request")
                return .failure(NetworkManager.unknownError)
            })
        )
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.url!.absoluteString, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.httpMethod!, "POST")
            XCTAssertEqual(r.allHTTPHeaderFields!["Content-Type"], "application/json")
            XCTAssertEqual(r.allHTTPHeaderFields!["FakeHeader"], "TestValue")
            let foundJSON = JSON(data : r.httpBody!)
            XCTAssertEqual(foundJSON, sampleJSON)
        }
    }
    
    func testFormEncodingPostConstruction() {
        let manager = NetworkManager(authorizationDataProvider: authProvider, baseURL: baseURL, cache : cache)
        let fields = [
            "Some field" : "true",
            "Some other field" : "some value"
        ]
        let apiRequest = NetworkRequest(
            method: HTTPMethod.POST,
            path: "/something",
            requiresAuth: true,
            body: RequestBody.formEncoded(fields),
            query: ["a" : JSON("b"), "c":JSON("d")],
            deserializer : .dataResponse({ (response, data) -> Result<Void> in
                XCTFail("Shouldn't send request")
                return .failure(NetworkManager.unknownError)
            })
        )
        
        AssertSuccess(manager.URLRequestWithRequest(apiRequest)) { r in
            XCTAssertEqual(r.url!.absoluteString, "http://example.com/something?a=b&c=d")
            XCTAssertEqual(r.httpMethod!, "POST")
            XCTAssertEqual(r.allHTTPHeaderFields!["Content-Type"], "application/x-www-form-urlencoded")
            XCTAssertEqual(r.allHTTPHeaderFields!["FakeHeader"], "TestValue")
            
            // Hackily extract form encoded fields
            let foundBody = String(data : r.httpBody!, encoding: String.Encoding.utf8)
            let items = foundBody?.components(separatedBy: "&") ?? []
            let pairs = items.map { return $0.components(separatedBy: "=") }
            
            // Sort since the fields are in arbitrary order
            let sortedPairs = pairs.sorted(by: { return $0.first! < $1.first! })
            print("pairs are \(sortedPairs)")
            XCTAssertEqual(NSArray(array: sortedPairs), NSArray(array: [["Some%20field", "true"], ["Some%20other%20field", "some%20value"]]))
        }
    }
    
    func testAccessTokenExpiry() {
        let manager = NetworkManager(authorizationDataProvider: authProvider, baseURL: baseURL, cache: cache)
        let expectation = expectation(description: "Request Completes")
        
        let apiRequest = NetworkRequest(
            method: .POST,
            path: "/something",
            requiresAuth: true,
            body: .emptyBody,
            deserializer: .dataResponse { _, _ -> Result<Void> in
                XCTFail("Shouldn't send request")
                return .failure(NetworkManager.unknownError)
            }
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            manager.taskForRequest(apiRequest) { _ in }
            expectation.fulfill()
        }
        
        OEXWaitForExpectations()
        
        XCTAssertEqual(manager.tokenStatus, AccessTokenStatus.expired)
    }
    
    func requestEnvironment() -> (MockNetworkManager, NetworkRequest<Data>, URLRequest) {
        let manager = MockNetworkManager(authorizationDataProvider: authProvider, baseURL: URL(string:"http://example.com")!)
        let request = NetworkRequest<Data> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .dataResponse({(_, data) in Result.success(data as Data)}))
        let urlRequest = manager.URLRequestWithRequest(request).value!
        return (manager, request, urlRequest)
    }
    
    func testStreamCacheHit() {
        // Tests that if a request is in cache, we will send it and then the actual value from the network
        
        let (manager, request, urlRequest) = requestEnvironment()
        let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
        let originalData = "original".data(using: String.Encoding.utf8)!
        // first warm the cache
        let cacheExpectation = expectation(description: "Cache Store Completed")
        manager.responseCache.setCacheResponse(response, withData: originalData, forRequest: urlRequest as URLRequest, completion: {
            cacheExpectation.fulfill()
        })
        OEXWaitForExpectations()
        
        // make a request
        let networkData = "network".data(using: String.Encoding.utf8)!
        manager.interceptWhenMatching({_ -> Bool in return true },
                                      afterDelay : 0.1,
                                      withResponse: {_ in
                                        return NetworkResult(request: urlRequest, response: response, data: networkData, baseData: networkData, error: nil)
            }
        )
        
        // save the results
        let results = MutableBox<[Data]>([])
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectation(description: "Request loaded from cache and regular")
        withExtendedLifetime(NSObject()) {(owner : NSObject) -> Void in
            stream.listen(owner, action: {
                var found = results.value
                found.append($0.value! as Data)
                results.value = found
                if found.count == 2 {
                    loadedExpectation.fulfill()
                }
            })
            OEXWaitForExpectations()
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
            OEXWaitForExpectations()
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
        OEXWaitForExpectations()
        XCTAssertFalse(stream.active)
        XCTAssertNotNil(stream.error)
    }
    
    func testCacheFilledRequestSuccess() {
        // Test that the cache gets an entry when the underlying request succeeds (e.g. network failure, not a 404
        
        let (manager, request, urlRequest) = requestEnvironment()
        let testData = "testData".data(using: String.Encoding.utf8)!
        let headers = ["a" : "b"]
        let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 404, httpVersion: nil, headerFields: headers)!
        manager.interceptWhenMatching({_ -> Bool in return true },
                                      withResponse: {_ in
                                        return NetworkResult<Data>(request: urlRequest, response: response, data: testData, baseData: testData, error: nil)
            }
        )
        let stream = manager.streamForRequest(request, persistResponse: true)
        let loadedExpectation = expectation(description: "Request finished")
        
        stream.listenOnce(self) {_ in
            loadedExpectation.fulfill()
        }
        OEXWaitForExpectations()
        
        let cacheExpectation = expectation(description: "Cache Load finished")
        manager.responseCache.fetchCacheEntryWithRequest(urlRequest) {
            XCTAssertEqual($0!.data!, testData)
            XCTAssertEqual($0!.statusCode, response.statusCode)
            XCTAssertEqual($0!.headers, headers)
            cacheExpectation.fulfill()
        }
        OEXWaitForExpectations()
    }
    
    func testAuthenticationActionAuthenticateSuccess() {
        let manager = NetworkManager(authorizationDataProvider: nil, baseURL: baseURL, cache : cache)
        
        let expectation = self.expectation(description: "Request Completes")
        let request = NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .jsonResponse({(_, json) in .success(json)}))
        
        let expectedStubResponse = simpleStubResponseBuilder(200, data: "{\"I Love\":\"Cake\"}")
        let stub200Response = OHHTTPStubs.stubRequests(passingTest: { (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return expectedStubResponse
        })
        
        let initialStubResponse = simpleStubResponseBuilder(401, data: "{\"error_code\":\"token_expired\"}")
        let stub401Response = OHHTTPStubs.stubRequests(passingTest: { (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return initialStubResponse
        })
        
        
        manager.authenticator = { (response, data, _) -> AuthenticationAction in
            if response!.statusCode == 401 {
                return AuthenticationAction.authenticate({ (networkManager, completion) in
                    OHHTTPStubs.removeStub(stub401Response)
                    return completion(true)
                })}
            else {
                OHHTTPStubs.removeStub(stub200Response)
                return AuthenticationAction.proceed
            }
        }
        
        manager.taskForRequest(request) { (response) in
            XCTAssertEqual(response.response?.statusCode, 200)
            XCTAssertEqual(response.data?.rawString(), "{\n  \"I Love\" : \"Cake\"\n}")
            expectation.fulfill()
        }
        OEXWaitForExpectations()
    }
    
    func testAuthenticationActionAuthenticateFailure() {
        let manager = NetworkManager(authorizationDataProvider: nil, baseURL: baseURL, cache : cache)
       
        let expectation = self.expectation(description: "Request Completes")
        let request = NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .jsonResponse({(_, json) in .success(json)}))
        
        let expectedStubResponse = simpleStubResponseBuilder(401, data: "{\"error_code\":\"token_expired\"}")
        let stub401Response = OHHTTPStubs.stubRequests(passingTest: { (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return expectedStubResponse
        })
        
        manager.authenticator = { (response, data, _) -> AuthenticationAction in
            return AuthenticationAction.authenticate({ (networkManager, completion) in
                OHHTTPStubs.removeStub(stub401Response)
                return completion(false)
            })
        }
        
        manager.taskForRequest(request) { (response) in
            XCTAssertEqual(response.response?.statusCode, 401)
            XCTAssertEqual(response.data, nil)
            expectation.fulfill()
        }
        OEXWaitForExpectations()
    }
    
    func simpleStubResponseBuilder(_ statusCode: Int32, data: String) -> OHHTTPStubsResponse{
        return OHHTTPStubsResponse(
            data: data.data(using: String.Encoding.utf8)!,
            statusCode: statusCode,
            headers: nil)
    }
}
