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
        case iOS = "ios"
        case disabledVersions = "DISABLED_FOR_VERSIONS"
        case selfPacedEnabled = "SELF_PACED_ENABLED"
        case instructorPacedEnabled = "INSTRUCTOR_PACED_ENABLED"
    }
    
    private var disabledVersions: [String] = []
    var selfPacedEnabled: Bool = false
    var instructorPacedEnabled: Bool = false
    
    private var enabled: Bool {
        return !disabledVersions.contains(Bundle.main.oex_shortVersionString())
    }
    
    init() { }
    
    init(dict: [String : Any]?) {
        guard let config = dict?[Keys.iOS.rawValue] as? [String : Any]
        else { return }
              
        disabledVersions = config[Keys.disabledVersions.rawValue] as? [String] ?? []
        selfPacedEnabled = enabled && config[Keys.selfPacedEnabled.rawValue] as? Bool ?? false
        instructorPacedEnabled = enabled && config[Keys.instructorPacedEnabled.rawValue] as? Bool ?? false
    }
    
    func toDictionary() -> [String : Any] {
        return [
            Keys.iOS.rawValue: [
                Keys.disabledVersions.rawValue: disabledVersions,
                Keys.selfPacedEnabled.rawValue: selfPacedEnabled,
                Keys.instructorPacedEnabled.rawValue: instructorPacedEnabled
            ]
        ]
    }
}
