//
//  CalendarSyncConfig.swift
//  edX
//
//  Created by Muhammad Umer on 21/05/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

struct CalendarSyncConfig: Codable {
    var enabled: Bool = false
    var selfPacedEnabled: Bool = false
    var instructorPacedEnabled: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case enabled = "ENABLED"
        case selfPacedEnabled = "SELF_PACED_ENABLED"
        case instructorPacedEnabled = "INSTRUCTOR_PACED_ENABLED"
    }
}
