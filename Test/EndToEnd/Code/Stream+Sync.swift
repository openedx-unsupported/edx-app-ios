//
//  Stream+Sync.swift
//  edX
//
//  Created by Akiva Leffert on 3/14/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

extension OEXStream {
    func waitForValue(_ timeout: TimeInterval = 10) -> OEXStream {
        let expirationDate = NSDate(timeIntervalSinceNow: timeout)
        while self.value == nil && NSDate().compare(expirationDate as Date) == .orderedAscending {
            let nextCheck = NSDate().addingTimeInterval(0.1)
            RunLoop.main.run(until: nextCheck as Date)
        }
        return self
    }
}
