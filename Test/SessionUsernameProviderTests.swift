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
        let path = OEXFileUtility.t_pathForUserName(user.username!)
        try! NSFileManager.defaultManager().removeItemAtPath(path)
    }

    func providerForUsername(user : OEXUserDetails) -> SessionUsernameProvider {
        let storage = OEXMockCredentialStorage()
        storage.storedAccessToken = OEXAccessToken.fakeToken()
        storage.storedUserDetails = user
        let session  = OEXSession(credentialStore: storage)
        session.loadTokenFromStore()
        let provider = SessionUsernameProvider(session: session)
        return provider
    }

    func testReturnsUserAppropriatePath() {
        let provider = providerForUsername(user)
        let path = provider.pathForRequestKey("123")
        XCTAssertTrue(path?.absoluteString.containsString(user.username!.oex_md5) ?? false)
    }

    func testWorksWithResponseCache() {
        let provider = providerForUsername(user)
        let cache = PersistentResponseCache(provider: provider)
        let URL = NSURL(string:"http://example.com")!
        let response = NSHTTPURLResponse(URL: URL, statusCode: 200, HTTPVersion: nil, headerFields: nil)!
        let request = NSURLRequest(URL: URL)
        let responseData = ("test" as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        cache.setCacheResponse(response, withData: responseData, forRequest: request)

        let expectation = expectationWithDescription("cache fulfilled")
        cache.fetchCacheEntryWithRequest(request) { (entry) -> Void in
            XCTAssertEqual(entry?.statusCode, 200)
            XCTAssertEqual(entry?.data, responseData)
            expectation.fulfill()
        }
        waitForExpectations()
    }

}
