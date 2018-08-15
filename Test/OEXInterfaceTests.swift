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
    var defaultsMockRemover : OEXRemovable!
    
    override func setUp() {
        defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
    }
    
    override func tearDown() {
        defaultsMockRemover.remove()
        OEXSession().closeAndClear()
    }
    
    func mockSessionCredentials() {
        let storage = OEXMockCredentialStorage()
        storage.storedAccessToken = OEXAccessToken.fake()
        storage.storedUserDetails = OEXUserDetails.freshUser()
        let session  = OEXSession(credentialStore: storage)
        session.loadTokenFromStore()
    }
    
    func testEnrollmentUrlWithUserAndWithOrganization() {
        for organizationCode in ["edX", "acme"] {
            mockSessionCredentials()
            
            let config = OEXConfig(dictionary: ["ORGANIZATION_CODE": organizationCode])
            let environment = TestRouterEnvironment(config: config, interface: nil)
            environment.logInTestUser()
            
            let URLString = NSMutableString(string: baseUrl)
            let enrollmentUrl = interface.formatEnrollmentURL(with: URLString)
            let includesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location != NSNotFound
            let includesOrgCodeInQueryParams = enrollmentUrl.range(of: organizationCode).location != NSNotFound
            let notIncludesTestAsUsername = enrollmentUrl.range(of: "test").location == NSNotFound
            
            XCTAssertTrue(includesOrgInQueryParams)
            XCTAssertTrue(includesOrgCodeInQueryParams)
            XCTAssertTrue(notIncludesTestAsUsername)
            
            OEXSession().closeAndClear()
        }
    }
    
    func testEnrollmentUrlWithoutUserAndWithOrganization() {
        for organizationCode in ["edX", "acme"] {
            let config = OEXConfig(dictionary: ["ORGANIZATION_CODE": organizationCode])
            let _ = TestRouterEnvironment(config: config, interface: nil)
            
            let URLString = NSMutableString(string: baseUrl)
            let enrollmentUrl = interface.formatEnrollmentURL(with: URLString)
            let notIncludesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location == NSNotFound
            let inlcudesTestAsUsername = enrollmentUrl.range(of: "test").location != NSNotFound
            
            XCTAssertTrue(notIncludesOrgInQueryParams)
            XCTAssertTrue(inlcudesTestAsUsername)
        }
    }
    
    func testEnrollmentUrlWithUserAndWithoutOrganization() {
        mockSessionCredentials()
        
        let config = OEXConfig()
        let environment = TestRouterEnvironment(config: config, interface: nil)
        environment.logInTestUser()
        
        let URLString = NSMutableString(string: baseUrl)
        let enrollmentUrl = interface.formatEnrollmentURL(with: URLString)
        let notIncludesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location == NSNotFound
        let notIncludesTestAsUsername = enrollmentUrl.range(of: "test").location == NSNotFound
        
        XCTAssertTrue(notIncludesOrgInQueryParams)
        XCTAssertTrue(notIncludesTestAsUsername)
        
        OEXSession().closeAndClear()
    }
    
    func testEnrollmentUrlWithoutUserAndWithoutOrganization() {
        let config = OEXConfig()
        let _ = TestRouterEnvironment(config: config, interface: nil)
        
        let URLString = NSMutableString(string: baseUrl)
        let enrollmentUrl = interface.formatEnrollmentURL(with: URLString)
        let notIncludesOrgInQueryParams = enrollmentUrl.range(of:"?org=").location == NSNotFound
        let includesTestAsUsername = enrollmentUrl.range(of: "test").location == NSNotFound
        
        XCTAssertTrue(notIncludesOrgInQueryParams)
        XCTAssertTrue(includesTestAsUsername)
    }
}
