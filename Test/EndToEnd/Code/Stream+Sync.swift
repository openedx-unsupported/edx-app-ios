//
//  Stream+Sync.swift
//  edX
//
//  Created by Akiva Leffert on 3/14/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

extension Stream {
    func waitForValue(timeout: NSTimeInterval = 10) -> Stream {
        let expirationDate = NSDate(timeIntervalSinceNow: timeout)
        while self.value == nil && NSDate().compare(expirationDate) == .OrderedAscending {
            let nextCheck = NSDate().dateByAddingTimeInterval(0.1)
            NSRunLoop.mainRunLoop().runUntilDate(nextCheck)
        }
        return self
    }
}