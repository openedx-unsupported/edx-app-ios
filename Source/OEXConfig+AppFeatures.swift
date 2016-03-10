//
//  OEXConfig+AppFeatures.swift
//  edX
//
//  Created by Akiva Leffert on 3/9/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXConfig {
    var pushNotificationsEnabled : Bool {
        return self.boolForKey("PUSH_NOTIFICATIONS")
    }

    var discussionsEnabled : Bool {
        return self.boolForKey("DISCUSSIONS_ENABLED")
    }

    var certificatesEnabled : Bool {
        return self.boolForKey("CERTIFICATES_ENABLED")
    }

    var profilesEnabled : Bool {
        return self.boolForKey("USER_PROFILES_ENABLED")
    }

    var courseSharingEnabled : Bool {
        return self.boolForKey("COURSE_SHARING_ENABLED")
    }

}
