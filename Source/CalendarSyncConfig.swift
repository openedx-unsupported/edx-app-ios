//
//  CalendarSyncConfig.swift
//  edX
//
//  Created by Muhammad Umer on 21/05/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

struct CalendarSyncConfig: Codable {
    private var enabled: Bool = false
    private var selfPacedEnabled: Bool = false
    private var instructorPacedEnabled: Bool = false
    
    var isSelfPacedEnabled: Bool {
        return enabled && selfPacedEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case enabled = "ENABLED"
        case selfPacedEnabled = "SELF_PACED_ENABLED"
        case instructorPacedEnabled = "INSTRUCTOR_PACED_ENABLED"
    }
    
    init() {
        self.enabled = false
        self.selfPacedEnabled = false
        self.instructorPacedEnabled = false
    }
    
    init(dict: [String : Bool]) {
        guard let enabled = dict[CodingKeys.enabled.rawValue],
              let selfPacedEnabled = dict[CodingKeys.enabled.rawValue],
              let instructorPacedEnabled = dict[CodingKeys.enabled.rawValue]
        else { return }
        
        self.enabled = enabled
        self.selfPacedEnabled = selfPacedEnabled
        self.instructorPacedEnabled = instructorPacedEnabled
    }
}
