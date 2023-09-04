//
//  VersionParserTests.swift
//  edX
//
//  Created by Saeed Bashir on 7/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
@testable import edX

class VersionParserTests: XCTestCase {
    func testVersionParsing() {
        let version = Version(version: "2.9.1")
        
        XCTAssertNotNil(version)
        XCTAssertNotNil(version.getMajorVersion())
        XCTAssertNotNil(version.getMinorVersion())
        XCTAssertNotNil(version.getPatchVersion())
        
        XCTAssertEqual(version.getMajorVersion(), Int("2"))
        XCTAssertEqual(version.getMinorVersion(), Int("9"))
        XCTAssertEqual(version.getPatchVersion(), Int("1"))
    }
    
    func testAlphaNumericVersionParing() {
        let version = Version(version: "2.9.alpha")
        
        XCTAssertNotNil(version)
        XCTAssertNotNil(version.getMajorVersion())
        XCTAssertNotNil(version.getMinorVersion())
        XCTAssertNotNil(version.getPatchVersion())
        
        XCTAssertEqual(version.getMajorVersion(), Int("2"))
        XCTAssertEqual(version.getMinorVersion(), Int("9"))
        XCTAssertEqual(version.getPatchVersion(), 0)
    }
    
    func testAlphaVersionParsing() {
        let version = Version(version: "abc.test.alpha")
        
        XCTAssertNotNil(version)
        // For non supported values major. minor and patch version will be 0
        XCTAssertEqual(version.getMajorVersion(), 0)
        XCTAssertEqual(version.getMinorVersion(), 0)
        XCTAssertEqual(version.getPatchVersion(), 0)
    }
    
    func testVersionDiff() {
        let minorVersion = Version(version: "2.9.0")
        let newVersion = Version(version: "2.10.0")
        
        XCTAssertTrue(newVersion.isNMinorVersionsDiff(otherVersion: minorVersion, minorVersionDiff: 0))
        XCTAssertTrue(newVersion.isNMinorVersionsDiff(otherVersion: minorVersion, minorVersionDiff: 1))
        XCTAssertFalse(minorVersion.isNMinorVersionsDiff(otherVersion: newVersion, minorVersionDiff: 2))
        
        let majorVersion = Version(version: "3.0.0")
        XCTAssertTrue(minorVersion.isNMinorVersionsDiff(otherVersion: majorVersion, minorVersionDiff: 2))
    }
    
    func testSameVersions() {
        let version = Version(version: "2.10")
        let sameVersion = Version(version: "2.10")
        
        XCTAssertTrue(sameVersion.isMajorMinorVersionsSame(otherVersion: version))
        
        // Test for patch version. Patch version should be ignored
        let patchVersion = Version(version: "2.10.1")
        XCTAssertTrue(patchVersion.isMajorMinorVersionsSame(otherVersion: version))
        
        // Test Different versions
        let newVersion = Version(version: "2.11")
        XCTAssertFalse(newVersion.isMajorMinorVersionsSame(otherVersion: version))
        
    }
}
