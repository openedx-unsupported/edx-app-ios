//
//  CalendarSyncConfig.swift
//  edX
//
//  Created by Muhammad Umer on 21/05/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

struct CalendarSyncConfig {
    private enum Keys: String {
        case iOS = "iOS"
        case enabledForAllVersionsExcept = "ENABLED_FOR_ALL_VERSIONS_EXCEPT"
        case selfPacedEnabled = "SELF_PACED_ENABLED"
        case instructorPacedEnabled = "INSTRUCTOR_PACED_ENABLED"
    }
    
    private var enabledForAllVersionsExcept: [String] = []
    private var selfPacedEnabled: Bool = false
    private var instructorPacedEnabled: Bool = false
    
    private var enabled: Bool {
        return !enabledForAllVersionsExcept.contains(Bundle.main.oex_buildVersionString())
    }
    
    var isSelfPacedEnabled: Bool {
        return enabled && selfPacedEnabled
    }
    
    init() {
        self.enabledForAllVersionsExcept = []
        self.selfPacedEnabled = false
        self.instructorPacedEnabled = false
    }
    
    init(dict: [String : Any]?) {
        guard let dict = dict,
              let config = dict[Keys.iOS.rawValue] as? [String : Any],
              let enabledForAllVersionsExcept = config[Keys.enabledForAllVersionsExcept.rawValue] as? [String],
              let selfPacedEnabled = config[Keys.selfPacedEnabled.rawValue] as? Bool,
              let instructorPacedEnabled = config[Keys.instructorPacedEnabled.rawValue] as? Bool
        else { return }
        
        self.enabledForAllVersionsExcept = enabledForAllVersionsExcept
        self.selfPacedEnabled = selfPacedEnabled
        self.instructorPacedEnabled = instructorPacedEnabled
    }
    
    func toDictionary() -> [String : Any] {
        return [
            Keys.iOS.rawValue: [
                Keys.enabledForAllVersionsExcept.rawValue: enabledForAllVersionsExcept,
                Keys.selfPacedEnabled.rawValue: selfPacedEnabled,
                Keys.instructorPacedEnabled.rawValue: instructorPacedEnabled
            ]
        ]
    }
}
