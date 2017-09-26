//
//  VersionParser.swift
//  edX
//
//  Created by Saeed Bashir on 7/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

class Version {
    
    private var numbers:[String] = []
    
    /* The first three present dot-separated tokens will be parsed as major, minor, and patch version
    numbers respectively, and any further tokens will be discarded. */
    
    init(version: String) {
        numbers = version.components(separatedBy: ".")
    }
    
    func getMajorVersion() -> Int {
        return getVersion(at: 0)
    }
    
    func getMinorVersion() -> Int {
        return getVersion(at: 1)
    }
    
    func getPatchVersion() -> Int {
        return getVersion(at: 2)
    }
    
    // Returns the version number at the provided index.
    // We are assuming every part of version as Int for calculation
    // 0 will be returned for non supported values
    private func getVersion(at index: Int) -> Int {
        return (index < numbers.count) ? Int(numbers[index]) ?? 0 : 0
    }
    
    func isNMinorVersionsDiff(otherVersion: Version, minorVersionDiff: Int) -> Bool {
        // Difference in major version is consider to be valid for any minor versions difference
        return (getMajorVersion() - otherVersion.getMajorVersion() >= 1) || (getMinorVersion() - otherVersion.getMinorVersion() >= minorVersionDiff)
    }
    
    func isMajorMinorVersionsSame(otherVersion: Version) -> Bool {
        return getMajorVersion() == otherVersion.getMajorVersion() && getMinorVersion() == otherVersion.getMinorVersion()
    }
}
