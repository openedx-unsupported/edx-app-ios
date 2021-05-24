//
//  CalendarSyncConfig.swift
//  edX
//
//  Created by Muhammad Umer on 21/05/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

struct CalendarSyncConfig: Codable {
    private enum Keys: String {
        case iOS = "iOS"
        case enabled = "ENABLED"
        case selfPacedEnabled = "SELF_PACED_ENABLED"
        case instructorPacedEnabled = "INSTRUCTOR_PACED_ENABLED"
    }
    
    private var enabled: Bool = false
    private var selfPacedEnabled: Bool = false
    private var instructorPacedEnabled: Bool = false
    
    var isSelfPacedEnabled: Bool {
        return enabled && selfPacedEnabled
    }
    
    init() {
        self.enabled = false
        self.selfPacedEnabled = false
        self.instructorPacedEnabled = false
    }
    
    init(dict: [String : Any]?) {
        guard let dict = dict,
              let config = dict[Keys.iOS.rawValue] as? [String : Bool],
              let enabled = config[Keys.enabled.rawValue],
              let selfPacedEnabled = config[Keys.selfPacedEnabled.rawValue],
              let instructorPacedEnabled = config[Keys.instructorPacedEnabled.rawValue]
        else { return }
        
        self.enabled = enabled
        self.selfPacedEnabled = selfPacedEnabled
        self.instructorPacedEnabled = instructorPacedEnabled
    }
    
    func toDictionary() -> [String : Any] {
        return [
            Keys.iOS.rawValue: [
                Keys.enabled.rawValue: enabled,
                Keys.selfPacedEnabled.rawValue: selfPacedEnabled,
                Keys.instructorPacedEnabled.rawValue: instructorPacedEnabled
            ]
        ]
    }
}
