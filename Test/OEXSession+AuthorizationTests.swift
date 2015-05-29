//
//  OEXSession+AuthorizationTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edX

class OEXSession_AuthorizationTests : XCTestCase {
    
    func testHeadersOpenSession() {
        let accessToken = OEXAccessToken()
        accessToken.accessToken = "KLJ34JKL34"
        accessToken.tokenType = "Bearer"
        
        let keychain = OEXMockCredentialStorage()
        keychain.storedAccessToken = accessToken
        keychain.storedUserDetails = OEXUserDetails()
        
        let session = OEXSession(credentialStore: keychain)
        session.loadTokenFromStore()
        
        XCTAssertEqual(session.authorizationHeaders, ["Authorization" : "Bearer KLJ34JKL34"])
    }
    
    func testHeadersNoSession() {
        let session = OEXSession(credentialStore: OEXMockCredentialStorage())
        session.loadTokenFromStore()
        
        XCTAssertEqual(session.authorizationHeaders, [:])
    }
    
    
}