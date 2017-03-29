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
    
    func loggedInContext() -> (OEXMockCredentialStorage, OEXSession, UserProfileManager, MockNetworkManager) {
        
        let credentialStorage = OEXMockCredentialStorage.freshStorage()
        let session = OEXSession(credentialStore: credentialStorage)
        session.loadTokenFromStore()
        
        let networkManager = MockNetworkManager(authorizationHeaderProvider: nil, baseURL: URL(string:"http://example.com")!)
        networkManager.interceptWhenMatching({ $0.method == .GET}, successResponse: {
            return (nil, UserProfile(username: credentialStorage.storedUserDetails!.username!))
        })
        
        let profileManager = UserProfileManager(networkManager: networkManager, session: session)
        
        return (credentialStorage, session, profileManager, networkManager)
    }
    
    func testCurrentUserSwapsFeed() {
        let (credentialStorage, session, profileManager, _) = loggedInContext()
        let feed = profileManager.feedForCurrentUser()
        
        var expectation = expectationWithDescription("Profile populated")
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
        expectation = expectationWithDescription("Profile removed")
        feed.output.listenOnce(self) {
            XCTAssertNil($0.value)
            expectation.fulfill()
        }
        
        session.loadTokenFromStore()
        
        // Log in back in should update user
        expectation = expectationWithDescription("Profile populated again")
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
    
    func testUpdate() {
        let (_, _, profileManager, networkManager) = loggedInContext()
        let profileFeed = profileManager.feedForCurrentUser()
        var profile : UserProfile!
        var expectation = expectationWithDescription("Profile populated")
        profileFeed.refresh()
        profileFeed.output.listenOnce(self) {
            profile = $0.value
            expectation.fulfill()
        }
        waitForExpectations()
        let newBio = "Test Passed"
        profile.updateDictionary = ["bio" : newBio]
        
        networkManager.interceptWhenMatching({ $0.method == .PATCH}) { () -> (Data?, UserProfile) in
            let newProfile = profile
            newProfile.bio = newBio
            return (nil, newProfile)
        }
        
        expectation = expectationWithDescription("Profile updated")
        profileManager.updateCurrentUserProfile(profile) { result -> Void in
            XCTAssertEqual(result.value!.bio, newBio)
            expectation.fulfill()
        }
        waitForExpectations()
        
        // We updated the profile so the current user feed should also fire
        expectation = expectationWithDescription("Profile feed update")
        profileFeed.output.listenOnce(self) {
            XCTAssertEqual($0.value!.bio!, newBio)
            expectation.fulfill()
        }
        waitForExpectations()
    }
    
    func testClearsOnLogOut() {
        let (_, session, profileManager, _) = loggedInContext()
        var feed = profileManager.feedForUser("some_test_person")
        feed.refresh()
        
        let expectation = expectationWithDescription("Profile loaded")
        feed.output.listenOnce(self) {_ in
            expectation.fulfill()
        }
        
        waitForExpectations()
        XCTAssertNotNil(feed.output.value!.username)
        session.closeAndClearSession()
        
        feed = profileManager.feedForUser("some_test_person")
        XCTAssertNil(feed.output.value)
        
    }
}
