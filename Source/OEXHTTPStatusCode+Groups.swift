//
//  OEXHTTPStatusCode+Groups.swift
//  edX
//
//  Created by Akiva Leffert on 8/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXHTTPStatusCode {
    var is4xx : Bool {
        let raw = self.rawValue
        return raw >= 400 && raw < 499
    }
}
