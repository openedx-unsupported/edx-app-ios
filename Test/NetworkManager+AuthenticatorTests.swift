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
            let expectation = self.expectation(description: "wait for mock LogOut")

            let removeable = NotificationCenter.default.oex_addObserver(observer: self, name: "MockLogOutCalled") { [weak router] (notification, _, _) in
                if router?.testType == notification.object as? String {
                    expectation.fulfill()
                }
            }

            waitForExpectations()
            removeable.remove()
        }

        return result
    }
    
    func testAuthenticatorDoesNothing() {
        let router = mockRouterBuilder()
        let session = OEXSession()
        let response = simpleResponseBuilder(200)
        let data = "{}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isProceed)
        XCTAssertFalse(router.logoutCalled)
    }
    
    func testLogoutWithNoRefreshToken() {
        let router = mockRouterBuilder()
        router.testType = "testLogoutWithNoRefreshToken"
        
        let session = OEXSession()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_expired\"}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: true)
        XCTAssertTrue(result.isProceed)
        XCTAssertTrue(router.logoutCalled)
    }
    
    func testNonExistentAccessToken() {
        let router = mockRouterBuilder()
        let session = sessionWithRefreshTokenBuilder()
        let response = simpleResponseBuilder(400)
        let data = "{\"error\":\"token_nonexistent\"}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isAuthenticate)
    }

    func testInvalidGrantAccessToken() {
        let router = mockRouterBuilder()
        let session = sessionWithRefreshTokenBuilder()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"invalid_grant\"}".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isProceed)
        XCTAssertFalse(router.logoutCalled)
    }
    
    func testLogoutWithNonJSONData() {
        let router = mockRouterBuilder()
        let session = OEXSession()
        let response = simpleResponseBuilder(200)
        let data = "I AM NOT A JSON".data(using: String.Encoding.utf8)!
        let result = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isProceed)
        XCTAssertFalse(router.logoutCalled)
    }
    
    func testExpiredAccessTokenReturnsAuthenticate() {
        let router = mockRouterBuilder()
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
    
    func testMultipleRequestsWithExpiredAccessToken() {
        let router = mockRouterBuilder()
        let session = sessionWithRefreshTokenBuilder()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_expired\"}".data(using: String.Encoding.utf8)!
        let firstResult = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        let secondResult = authenticatorResponseForRequest(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(firstResult.isAuthenticate)
        XCTAssertTrue(secondResult.isQueued)
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
    
    func mockRouterBuilder() -> MockRouter {
        return MockRouter(environment: TestRouterEnvironment(config: OEXConfig(dictionary:[:]), interface: OEXInterface.shared()))
    }
}
