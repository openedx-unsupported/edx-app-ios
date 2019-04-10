//
//  OEXInterfaceTests.swift
//  edXTests
//
//  Created by Jose Antonio Gonzalez on 2018/07/12.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest
import edXCore
@testable import edX

class OEXInterfaceTests: XCTestCase {
    
    let interface = OEXInterface()
    let baseUrl = "https://courses.edx.org"
    let organizationCode = "edX"
    var defaultsMockRemover : OEXRemovable!
    
    override func setUp() {
        defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
    }
    
    override func tearDown() {
        defaultsMockRemover.remove()
        OEXSession.shared()?.closeAndClear()
    }
    
    func mockSessionCredentials() {
        let storage = OEXMockCredentialStorage()
        storage.storedAccessToken = OEXAccessToken.fake()
        storage.storedUserDetails = OEXUserDetails.freshUser()
        let session  = OEXSession(credentialStore: storage)
        OEXSession.setShared(session)
        session.loadTokenFromStore()
    }
}
