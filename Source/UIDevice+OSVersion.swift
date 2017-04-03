//
//  UIDevice+OSVersion.swift
//  edX
//
//  Created by Akiva Leffert on 6/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIDevice {
    /// This is only for use from Objective-C code. Swift code should use
    /// if #available.
    private func isOSVersionAtLeast(version : Int) -> Bool {
        return UIDevice.current.systemVersion.compare(String(version), options: NSString.CompareOptions.numeric) != .orderedAscending
    }
    
    /// This is only for use from Objective-C code. Swift code should use
    /// if #available.
    class func isOSVersionAtLeast9() -> Bool {
        return current.isOSVersionAtLeast(version: 9)
    }
}
