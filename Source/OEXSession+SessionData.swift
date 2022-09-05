//
//  OEXSession+SessionData.swift
//  edX
//
//  Created by AsifBilal on 8/24/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

extension OEXSession: SessionDataProvider {
    public var isUserLoggedIn: Bool {
        return currentUser != nil
    }
    
    public var tokenExpiryDuration: NSNumber? {
        return token?.tokenExpiryDuration
    }
    
    public var tokenExpiryDate: Date? {
        return token?.savedOnDate
    }
}
