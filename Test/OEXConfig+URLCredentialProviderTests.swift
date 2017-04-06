//
//  OEXConfig+URLCredentialProviderTests.swift
//  edX
//
//  Created by Akiva Leffert on 11/9/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest

class OEXConfig_URLCredentialProviderTests: XCTestCase {

    static let credentials = [
        [
            "HOST" : "https://somehost.com",
            "USERNAME" : "someuser",
            "PASSWORD" : "abc123"
        ],
        [
            "HOST" : "https://otherhost.com",
            "USERNAME" : "meeee",
            "PASSWORD" : "miiiine",
        ]
    ]
    
    let config = OEXConfig(dictionary:["BASIC_AUTH_CREDENTIALS" : credentials])
    
    func testHit() {
        for group in type(of: self).credentials {
            let host = URL(string:group["HOST"]!)!.host!
            let credential = config.URLCredentialForHost(host as NSString)
            XCTAssertNotNil(credential)
            XCTAssertEqual(credential!.user, group["USERNAME"]!)
            XCTAssertEqual(credential!.password, group["PASSWORD"]!)
            XCTAssertEqual(credential!.persistence, URLCredential.Persistence.forSession)
        }
    }
    
    func testMiss() {
        let credential = config.URLCredentialForHost("unknown")
        XCTAssertNil(credential)
    }
    
}
