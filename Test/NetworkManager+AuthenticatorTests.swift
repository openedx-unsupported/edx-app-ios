//
//  NetworkManager+AuthenticatorTests.swift
//  edX
//
//  Created by Christopher Lee on 5/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class NetworkManager_AuthenticationTests : XCTestCase {
    
    func checkInvalidAccessAuthenticatorWithResponse(
        response: NSHTTPURLResponse, data: NSData, session: OEXSession, router: MockRouter, waitForLogout: Bool) -> AuthenticationAction {
        let clientId = "dummy client_id"
        let result = NetworkManager.invalidAccessAuthenticator(router, session: session, clientId: clientId, response: response, data: data)
        
        if waitForLogout {
            expectationForPredicate(NSPredicate(format:"self.logoutCalled == true"), evaluatedWithObject: router, handler: nil)
            waitForExpectations()
        }
        return result
    }
    
    func testInvalidAccessAuthenticatorDoesNothing() {
        let router = MockRouter()
        let session = OEXSession()
        let response = simpleResponseBuilder(200)
        let data = "{}".dataUsingEncoding(NSUTF8StringEncoding)!
        let result = checkInvalidAccessAuthenticatorWithResponse(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isProceed)
        XCTAssertFalse(router.logoutCalled)
    }
    
    func testInvalidAccessAuthenticatorLogoutWithNoRefreshToken() {
        let router = MockRouter()
        let session = OEXSession()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_expired\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        let result = checkInvalidAccessAuthenticatorWithResponse(response!, data: data, session: session, router: router, waitForLogout: true)
        XCTAssertTrue(result.isProceed)
        XCTAssertTrue(router.logoutCalled)
    }
    
    func testInvalidAccessAuthenticatorLogoutForErrorsOtherThanExpiredAccessToken() {
        let router = MockRouter()
        let session = sessionWithRefreshTokenBuilder()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_nonexistent\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        let result = checkInvalidAccessAuthenticatorWithResponse(response!, data: data, session: session, router: router, waitForLogout: true)
        XCTAssertTrue(result.isProceed)
        XCTAssertTrue(router.logoutCalled)
        
    }
    
    func testInvalidAccessAuthenticatorLogoutWithNonJSONData() {
        let router = MockRouter()
        let session = OEXSession()
        let response = simpleResponseBuilder(200)
        let data = "I AM NOT A JSON".dataUsingEncoding(NSUTF8StringEncoding)!
        let result = checkInvalidAccessAuthenticatorWithResponse(response!, data: data, session: session, router: router, waitForLogout: true)
        XCTAssertTrue(result.isProceed)
        XCTAssertTrue(router.logoutCalled)
    }
    
    func testInvalidAccessAuthenticatorReturnsAuthenticate() {
        let router = MockRouter()
        let session = sessionWithRefreshTokenBuilder()
        let response = simpleResponseBuilder(401)
        let data = "{\"error_code\":\"token_expired\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        let result = checkInvalidAccessAuthenticatorWithResponse(response!, data: data, session: session, router: router, waitForLogout: false)
        XCTAssertTrue(result.isAuthenticate)
    }
    
    func testAuthenticationActionAuthenticateSuccess() {
        let manager = NetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string:"http://example.com")!, cache : MockResponseCache())
        
        let expectation = expectationWithDescription("Request Completes")
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
        
        let stub401Response = OHHTTPStubs.stubRequestsPassingTest({ (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return self.simpleStubResponseBuilder(401, data: "{\"error_code\":\"token_expired\"}")
        })
        
        
        manager.setupAuthenticator { (response, data) -> AuthenticationAction in
            if response.statusCode == 401 {
                return AuthenticationAction.Authenticate({ (networkManager, completion) in
                    OHHTTPStubs.removeStub(stub401Response)
                    return completion(success: true)
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
        let manager = NetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string:"http://example.com")!, cache : MockResponseCache())
        
        let expectation = expectationWithDescription("Request Completes")
        let request = NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .JSONResponse({(_, json) in .Success(json)}))
    
        let stub401Response = OHHTTPStubs.stubRequestsPassingTest({ (_) -> Bool in
            return true
            }, withStubResponse: { (_) -> OHHTTPStubsResponse in
                return self.simpleStubResponseBuilder(401, data: "{\"error_code\":\"token_expired\"}")
        })
        
        
        manager.setupAuthenticator { (response, data) -> AuthenticationAction in
            return AuthenticationAction.Authenticate({ (networkManager, completion) in
                OHHTTPStubs.removeStub(stub401Response)
                return completion(success: false)
            })
        }
        
        manager.taskForRequest(request) { (response) in
            XCTAssertEqual(response.response?.statusCode, 401)
            XCTAssertEqual(response.data, nil)
            expectation.fulfill()
        }
        waitForExpectations()
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
    
    func simpleResponseBuilder(statusCode: Int) -> NSHTTPURLResponse?{
        return NSHTTPURLResponse(
            URL: NSURL(),
            statusCode: statusCode,
            HTTPVersion: nil,
            headerFields: nil)
    }
    
    func simpleStubResponseBuilder(statusCode: Int32, data: String) -> OHHTTPStubsResponse{
        return OHHTTPStubsResponse(
            data: data.dataUsingEncoding(NSUTF8StringEncoding)!,
            statusCode: statusCode,
            headers: nil)
    }
    
    func simpleRequestBuilder() -> NetworkRequest<JSON> {
        return NetworkRequest<JSON> (
            method: HTTPMethod.GET,
            path: "path",
            deserializer: .JSONResponse({(_, json) in .Success(json)}))
        
    }
}