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
        return bool(forKey: "PUSH_NOTIFICATIONS")
    }

    var discussionsEnabled : Bool {
        return bool(forKey: "DISCUSSIONS_ENABLED")
    }
    
    var courseDatesEnabled : Bool {
        return bool(forKey: "COURSE_DATES_ENABLED")
    }

    var certificatesEnabled : Bool {
        return bool(forKey: "CERTIFICATES_ENABLED")
    }

    var profilesEnabled : Bool {
        return bool(forKey: "USER_PROFILES_ENABLED")
    }

    var courseSharingEnabled : Bool {
        return bool(forKey: "COURSE_SHARING_ENABLED")
    }

    var badgesEnabled : Bool {
        return bool(forKey: "BADGES_ENABLED")
    }
    
    var newLogistrationFlowEnabled: Bool {
        return bool(forKey: "NEW_LOGISTRATION_ENABLED")
    }
    
    var discussionsEnabledProfilePictureParam: Bool {
        return bool(forKey: "DISCUSSIONS_ENABLE_PROFILE_PICTURE_PARAM")
    }
    
    var isRegistrationEnabled: Bool {
        // By default registration is enabled
        return bool(forKey: "REGISTRATION_ENABLED", defaultValue: true)
    }
    
    var isFirebaseEnabled: Bool {
        let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") ?? ""
        if FileManager.default.fileExists(atPath: filePath) {
            return bool(forKey: "FIREBASE_ENABLED")
        }
        
        return false
    }
        
    var isVideoTranscriptEnabled : Bool {
        return bool(forKey: "VIDEO_TRANSCRIPT_ENABLED")
    }
    
    var isAppReviewsEnabled : Bool {
        return bool(forKey: "APP_REVIEWS_ENABLED")
    }
    
    var isWhatsNewEnabled: Bool {
        return bool(forKey: "WHATS_NEW_ENABLED")
    }
    
    var isCourseVideosEnabled: Bool {
        // By default course videos are enabled
        return bool(forKey: "COURSE_VIDEOS_ENABLED", defaultValue: true)
    }
    
    var isUsingVideoPipeline: Bool {
        // By default using video pipeline is enabled
        return bool(forKey: "USING_VIDEO_PIPELINE", defaultValue: true)
    }
  
    var isAnnouncementsEnabled: Bool {
        return bool(forKey: "ANNOUNCEMENTS_ENABLED")
    }
}
