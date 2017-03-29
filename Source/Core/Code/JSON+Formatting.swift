//
//  JSON+Formatting.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

extension JSON {
    var serverDate : Date? {
        return string.map { OEXDateFormatting.date(withServerString: $0) }
    }
}
