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
        return boolForKey("PUSH_NOTIFICATIONS")
    }

    var discussionsEnabled : Bool {
        return boolForKey("DISCUSSIONS_ENABLED")
    }

    var certificatesEnabled : Bool {
        return boolForKey("CERTIFICATES_ENABLED")
    }

    var profilesEnabled : Bool {
        return boolForKey("USER_PROFILES_ENABLED")
    }

    var courseSharingEnabled : Bool {
        return boolForKey("COURSE_SHARING_ENABLED")
    }

    var badgesEnabled : Bool {
        return boolForKey("BADGES_ENABLED")
    }
    
    var newLogistrationFlowEnabled: Bool {
        return boolForKey("NEW_LOGISTRATION_ENABLED")
    }
    
    var discussionsEnabledProfilePictureParam: Bool {
        return boolForKey("DISCUSSIONS_ENABLE_PROFILE_PICTURE_PARAM")
    }
    
    var isOnlySignInEnabled: Bool {
        return boolForKey("SIGN_IN_ONLY_ENABLED")
    }
    
}
