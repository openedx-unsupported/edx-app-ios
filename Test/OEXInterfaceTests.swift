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
    
    func testEnrollmentUrlWithUserAndWithOrganization() {
        mockSessionCredentials()
        let config = OEXConfig(dictionary: ["ORGANIZATION_CODE": organizationCode])
        let URLString = NSMutableString(string: baseUrl)
        let enrollmentUrl = interface.formatEnrollmentURL(with: config, url: URLString)
        let includesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location != NSNotFound
        let includesOrgCodeInQueryParams = enrollmentUrl.range(of: organizationCode).location != NSNotFound
        let notIncludesTestAsUsername = enrollmentUrl.range(of: "test").location == NSNotFound
        print(enrollmentUrl)
        XCTAssertTrue(includesOrgInQueryParams)
        XCTAssertTrue(includesOrgCodeInQueryParams)
        XCTAssertTrue(notIncludesTestAsUsername)
        
        OEXSession.shared()?.closeAndClear()
    }
    
    func testEnrollmentUrlWithoutUserAndWithOrganization() {
        let config = OEXConfig(dictionary: ["ORGANIZATION_CODE": organizationCode])
        let URLString = NSMutableString(string: baseUrl)
        let enrollmentUrl = interface.formatEnrollmentURL(with: config, url: URLString)
        let notIncludesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location == NSNotFound
        let includesTestAsUsername = enrollmentUrl.range(of: "test").location != NSNotFound
        
        XCTAssertTrue(notIncludesOrgInQueryParams)
        XCTAssertTrue(includesTestAsUsername)
    }
    
    func testEnrollmentUrlWithUserAndWithoutOrganization() {
        mockSessionCredentials()
        let config = OEXConfig()
        let URLString = NSMutableString(string: baseUrl)
        let enrollmentUrl = interface.formatEnrollmentURL(with: config, url: URLString)
        let notIncludesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location == NSNotFound
        let notIncludesTestAsUsername = enrollmentUrl.range(of: "test").location == NSNotFound
        
        XCTAssertTrue(notIncludesOrgInQueryParams)
        XCTAssertTrue(notIncludesTestAsUsername)
        
        OEXSession.shared()?.closeAndClear()
    }
    
    func testEnrollmentUrlWithoutUserAndWithoutOrganization() {
        let config = OEXConfig()
        let URLString = NSMutableString(string: baseUrl)
        let enrollmentUrl = interface.formatEnrollmentURL(with: config, url: URLString)
        let notIncludesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location == NSNotFound
        let includesTestAsUsername = enrollmentUrl.range(of: "test").location != NSNotFound
        
        XCTAssertTrue(notIncludesOrgInQueryParams)
        XCTAssertTrue(includesTestAsUsername)
    }
}
