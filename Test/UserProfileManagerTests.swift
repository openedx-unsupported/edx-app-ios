//
//  UserProfileManagerTests.swift
//  edX
//
//  Created by Akiva Leffert on 10/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

@testable import edX
import Foundation

class UserProfileManagerTests : XCTestCase {
    
    func testCurrentUserSwapsFeed() {
        let credentialStorage = OEXMockCredentialStorage.freshStorage()
        let session = OEXSession(credentialStore: credentialStorage)
        session.loadTokenFromStore()
        
        let networkManager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: NSURL(string:"http://example.com")!)
        networkManager.interceptWhenMatching({ _ in return true}, successResponse: {
            return (nil, UserProfile(username: credentialStorage.storedUserDetails!.username!))
        })
        
        let manager = UserProfileManager(networkManager: networkManager, session: session)
        let feed = manager.feedForCurrentUser()
        
        var expectation = expectationWithDescription("profile populated")
        feed.refresh()
        
        // Initial log in should include user
        var removable = feed.output.listen(self) {
            if let value = $0.value {
                XCTAssertEqual(value.username!, credentialStorage.storedUserDetails!.username!)
                expectation.fulfill()
            }
        }
        waitForExpectations()
        removable.remove()
        
        session.closeAndClearSession()
        credentialStorage.storedAccessToken = OEXAccessToken.fakeToken()
        credentialStorage.storedUserDetails = OEXUserDetails.freshUser()
        
        // Log out should remove user
        expectation = expectationWithDescription("profile removed")
        feed.output.listenOnce(self) {
            XCTAssertNil($0.value)
            expectation.fulfill()
        }
        
        session.loadTokenFromStore()
        
        // Log in back in should update user
        expectation = expectationWithDescription("profile populated again")
        feed.refresh()
        removable = feed.output.listen(self) {
            if let value = $0.value {
                XCTAssertEqual(value.username!, credentialStorage.storedUserDetails!.username!)
                expectation.fulfill()
            }
        }
        waitForExpectations()
        removable.remove()
    }
}