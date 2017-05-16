//
//  OEXInterface+WhatsNew.swift
//  edX
//
//  Created by Saeed Bashir on 5/10/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

private let WhatsNewShownFor = "whats_new_show_for"

extension OEXInterface {
    // save current version of app on whatsNew appearance
    func saveAppVersionOnWhatsNewAppear() {
        UserDefaults.standard.set(Bundle.main.oex_shortVersionString(), forKey: WhatsNewShownFor)
        UserDefaults.standard.synchronize()
    }
    
    // Get the saved app version when whatsNew presented to user
    func getSavedAppVersionForWhatsNew() -> String? {
        return UserDefaults.standard.string(forKey: WhatsNewShownFor)
    }
}
