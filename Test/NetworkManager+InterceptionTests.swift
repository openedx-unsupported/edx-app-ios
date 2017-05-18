//
//  NetworkManager+InterceptionTests.swift
//  edX
//
//  Created by Akiva Leffert on 3/14/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
class NetworkManager_InterceptionTests : XCTestCase {

    func checkJSONInterceptionWithStubResponse(_ router: OEXRouter, stubResponse : OHHTTPStubsResponse, verifier : @escaping (Result<JSON>) -> Void) {

        let manager = NetworkManager(authorizationHeaderProvider: nil, baseURL: URL(string:"http://example.com")!, cache : MockResponseCache())
        manager.addStandardInterceptors()
        let request = NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .jsonResponse({(_, json) in .success(json)}))

        manager.addJSONInterceptor {(response : HTTPURLResponse?, json : JSON) in
            if response?.statusCode ?? 0 == 401 {
                return .failure(NSError(domain: "{}", code: -100, userInfo: [:]))
            }
            else {
                return .success(json)
            }
        }

        let stub = OHHTTPStubs.stubRequests(passingTest: { (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return stubResponse
        })

        let expectations = expectation(description: "Request Completes")
        let stream = manager.streamForRequest(request, autoCancel : false)

        stream.extendLifetimeUntilFirstResult {
            verifier($0)
            expectations.fulfill()
        }

        waitForExpectations()

        OHHTTPStubs.removeStub(stub)
    }

    func testJSONInterceptionPassthrough() {
        let router = MockRouter()
        checkJSONInterceptionWithStubResponse(router, stubResponse:OHHTTPStubsResponse(data: "{}".data(using: String.Encoding.utf8)!, statusCode: 404, headers: nil), verifier: {
            XCTAssertTrue($0.value != nil)
            XCTAssertFalse(router.logoutCalled)
        })
    }

    // When running tests, we don't want network requests to actually work
    func testNetworkNotLive() {
        let manager = NetworkManager(authorizationHeaderProvider: nil, baseURL: URL(string:"https://google.com")!, cache : MockResponseCache())

        let apiRequest = NetworkRequest(method: HTTPMethod.GET, path: "/", deserializer : .dataResponse({_ -> Result<NSObject> in
            XCTFail("Shouldn't receive data")
            return .failure(NetworkManager.unknownError)
        }))
        // make sure this is a valid request
        AssertSuccess(manager.URLRequestWithRequest(apiRequest))

        let expectations = expectation(description: "Request dispatched")
        manager.taskForRequest(apiRequest) { result in
            XCTAssertNil(result.data)
            expectations.fulfill()
        }
        self.waitForExpectations()
    }


}
