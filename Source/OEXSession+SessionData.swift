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
        return userExists()
    }
    
    public var tokenExpiryDuration: NSNumber? {
        return token?.expiryDuration
    }
    
    public var tokenExpiryDate: Date? {
        return token?.creationDate
    }
}
