//
//  RemoteImageTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
@testable import edX

private class StubHeaderProvider : AuthorizationHeaderProvider {
    @objc var authorizationHeaders: [String : String] = ["test-header": "fake-value"]
}

class RemoteImageTests: XCTestCase {

    func makeFailingRequestWithURL(_ url: String) -> NetworkResult<RemoteImage> {
        let stub = OHHTTPStubs.stubRequests(passingTest: { _ in true }) {request in
            return OHHTTPStubsResponse(error: NetworkManager.unknownError)
        }

        let networkManager = NetworkManager(authorizationHeaderProvider: StubHeaderProvider(), credentialProvider: nil, baseURL: URL(string:"http://example.com")!, cache: MockResponseCache())

        let remoteImage = RemoteImageImpl(url: url, networkManager: networkManager, placeholder: nil, persist: false)

        let expectation = self.expectation(description: "image loaded")
        let box = MutableBox<NetworkResult<RemoteImage>?>(nil)
        remoteImage.fetchImage { response in
            box.value = response
            expectation.fulfill()
        }
        waitForExpectations()

        OHHTTPStubs.removeStub(stub)
        return box.value!
    }

    func testRelativeURLSendsAuthToken() {
        let response = makeFailingRequestWithURL("relative-path")
        XCTAssertEqual(response.request!.allHTTPHeaderFields!["test-header"], "fake-value")
    }

    func testAbsoluteURLSendsNoAuthToken() {
        let response = makeFailingRequestWithURL("http://absolu.te/path")
        XCTAssertNil(response.request!.allHTTPHeaderFields!["test-header"])
    }

    func testAbsoluteURLMatchingBaseSendsAuthToken() {
        let response = makeFailingRequestWithURL("http://example.com/path")
        XCTAssertEqual(response.request!.allHTTPHeaderFields!["test-header"], "fake-value")
    }

}
