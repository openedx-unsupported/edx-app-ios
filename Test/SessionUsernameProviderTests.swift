//
//  SessionUsernameProviderTests.swift
//  edX
//
//  Created by Akiva Leffert on 3/25/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest

import edX

class SessionUsernameProviderTests: XCTestCase {

    var user : OEXUserDetails!

    override func setUp() {
        super.setUp()
        user = OEXUserDetails.freshUser()
    }

    override func tearDown() {
        super.tearDown()
        let path = OEXFileUtility.t_path(forUserName: user.username!)
        try? FileManager.default.removeItem(atPath: path)
    }

    func providerForUsername(_ user : OEXUserDetails) -> SessionUsernameProvider {
        let storage = OEXMockCredentialStorage()
        storage.storedAccessToken = OEXAccessToken.fake()
        storage.storedUserDetails = user
        let session  = OEXSession(credentialStore: storage)
        session.loadTokenFromStore()
        let provider = SessionUsernameProvider(session: session)
        return provider
    }

    func testReturnsUserAppropriatePath() {
        let provider = providerForUsername(user)
        let path = provider.pathForRequestKey("123")
        XCTAssertTrue(path?.absoluteString.contains(user.username!.oex_md5) ?? false)
    }

    func testWorksWithResponseCache() {
        let provider = providerForUsername(user)
        let cache = PersistentResponseCache(provider: provider)
        let URL = Foundation.URL(string:"http://example.com")!
        let response = HTTPURLResponse(url: URL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let request = URLRequest(url: URL)
        let responseData = ("test" as NSString).data(using: String.Encoding.utf8.rawValue)
        cache.setCacheResponse(response, withData: responseData, forRequest: request)

        let expectation = self.expectation(description: "cache fulfilled")
        cache.fetchCacheEntryWithRequest(request) { (entry) -> Void in
            XCTAssertEqual(entry?.statusCode, 200)
            XCTAssertEqual(entry?.data, responseData)
            expectation.fulfill()
        }
        waitForExpectations()
    }

}
