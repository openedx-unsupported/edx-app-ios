//
//  UIDevice+OSVersion.swift
//  edX
//
//  Created by Akiva Leffert on 6/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension UIDevice {
    private func isOSVersionAtLeast(version : Int) -> Bool {
        return UIDevice.currentDevice().systemVersion.compare(String(version), options: NSStringCompareOptions.NumericSearch) != .OrderedAscending
    }
    
    func isOSVersionAtLeast8() -> Bool {
        return isOSVersionAtLeast(8)
    }
    
    class func isOSVersionAtLeast8() -> Bool {
        return currentDevice().isOSVersionAtLeast8()
    }
}