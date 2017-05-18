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
        
        let credentialStorage = OEXMockCredentialStorage.fresh()
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
        
        var testExpectation = expectation(description: "Profile populated")
        feed.refresh()
        
        // Initial log in should include user
        var removable = feed.output.listen(self) {
            if let value = $0.value {
                XCTAssertEqual(value.username!, credentialStorage.storedUserDetails!.username!)
                testExpectation.fulfill()
            }
        }
        waitForExpectations()
        removable.remove()
        
        session.closeAndClear()
        credentialStorage.storedAccessToken = OEXAccessToken.fake()
        credentialStorage.storedUserDetails = OEXUserDetails.freshUser()
        
        // Log out should remove user
        testExpectation = expectation(description: "Profile removed")
        feed.output.listenOnce(self) {
            XCTAssertNil($0.value)
            testExpectation.fulfill()
        }
        
        session.loadTokenFromStore()
        
        // Log in back in should update user
        testExpectation = expectation(description: "Profile populated again")
        feed.refresh()
        removable = feed.output.listen(self) {
            if let value = $0.value {
                XCTAssertEqual(value.username!, credentialStorage.storedUserDetails!.username!)
                testExpectation.fulfill()
            }
        }
        waitForExpectations()
        removable.remove()
    }
    
    func testUpdate() {
        let (_, _, profileManager, networkManager) = loggedInContext()
        let profileFeed = profileManager.feedForCurrentUser()
        var profile : UserProfile!
        var testExpectation = expectation(description: "Profile populated")
        profileFeed.refresh()
        profileFeed.output.listenOnce(self) {
            profile = $0.value
            testExpectation.fulfill()
        }
        waitForExpectations()
        let newBio = "Test Passed"
        profile.updateDictionary = ["bio" : newBio as AnyObject]
        
        networkManager.interceptWhenMatching({ $0.method == .PATCH}) { () -> (Data?, UserProfile) in
            let newProfile = profile
            newProfile?.bio = newBio
            return (nil, newProfile!)
        }
        
        testExpectation = expectation(description: "Profile updated")
        profileManager.updateCurrentUserProfile(profile: profile) { result -> Void in
            XCTAssertEqual(result.value!.bio, newBio)
            testExpectation.fulfill()
        }
        waitForExpectations()
        
        // We updated the profile so the current user feed should also fire
        testExpectation = expectation(description: "Profile feed update")
        profileFeed.output.listenOnce(self) {
            XCTAssertEqual($0.value!.bio!, newBio)
            testExpectation.fulfill()
        }
        waitForExpectations()
    }
    
    func testClearsOnLogOut() {
        let (_, session, profileManager, _) = loggedInContext()
        var feed = profileManager.feedForUser(username: "some_test_person")
        feed.refresh()
        
        let testExpectation = expectation(description: "Profile loaded")
        feed.output.listenOnce(self) {_ in
            testExpectation.fulfill()
        }
        
        waitForExpectations()
        XCTAssertNotNil(feed.output.value!.username)
        session.closeAndClear()
        
        feed = profileManager.feedForUser(username: "some_test_person")
        XCTAssertNil(feed.output.value)
        
    }
}
