//
//  NetworkManager+AuthenticatorTests.swift
//  edX
//
//  Created by Christopher Lee on 5/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class NetworkManager_AuthenticationTests : XCTestCase {
    
    func authenticatorResponseForRequest(
        _ response: HTTPURLResponse, data: Data, session: OEXSession, router: MockRouter, waitForLogout: Bool) -> AuthenticationAction {
        let clientId = "dummy client_id"
        let result = NetworkManager.invalidAccessAuthenticator(router: router, session: session, clientId: clientId, response: response, data: data)
        
        if waitForLogout {
            expectation(for: NSPredicate(format:"self.logoutCalled == true"), evaluatedWith: router, handler: nil)
            waitForExpectations()
        }
        return result
    }
    
    func testAuthenticatorDoesNothing() {
        let router = MockRouter()
        let session = OEXSession()
        let response = simpleResponseBuilder(200)
        let data = "{}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isProceed)
        XCTAssertFalse(router.logoutCalled)
    }
    
    func testLogoutWithNoRefreshToken() {
        let router = MockRouter()
        let session = OEXSession()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_expired\"}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: true)
        XCTAssertTrue(result.isProceed)
        XCTAssertTrue(router.logoutCalled)
    }
    
    func testLogoutForErrorsOtherThanExpiredAccessToken() {
        let router = MockRouter()
        let session = sessionWithRefreshTokenBuilder()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_nonexistent\"}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: true)
        XCTAssertTrue(result.isProceed)
        XCTAssertTrue(router.logoutCalled)
        
    }
    
    func testLogoutWithNonJSONData() {
        let router = MockRouter()
        let session = OEXSession()
        let response = simpleResponseBuilder(200)
        let data = "I AM NOT A JSON".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isProceed)
        XCTAssertFalse(router.logoutCalled)
    }
    
    func testExpiredAccessTokenReturnsAuthenticate() {
        let router = MockRouter()
        let session = sessionWithRefreshTokenBuilder()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_expired\"}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isAuthenticate)
    }
    

    func sessionWithRefreshTokenBuilder() -> OEXSession {
        let accessToken = OEXAccessToken()
        accessToken.refreshToken = "dummy refresh token"
        let keychain = OEXMockCredentialStorage()
        keychain.storedAccessToken = accessToken
        keychain.storedUserDetails = OEXUserDetails()
        let session = OEXSession(credentialStore: keychain)
        session.loadTokenFromStore()
        return session
    }
    
    func simpleResponseBuilder(_ statusCode: Int) -> HTTPURLResponse?{
        return HTTPURLResponse(
            url: URL(string: "http://www.example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil)
    }
    
    func simpleRequestBuilder() -> NetworkRequest<JSON> {
        return NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .jsonResponse({(_, json) in .success(json)}))
    }
}
