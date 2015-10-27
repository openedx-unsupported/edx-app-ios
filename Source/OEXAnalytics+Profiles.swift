//
//  OEXAnalytics+Profiles.swift
//  edX
//
//  Created by Michael Katz on 10/26/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

enum AnaylticsPhotoSource {
    case Camera
    case PhotoLibrary
    
    var value : String {
        switch self {
            case .Camera: return OEXAnalyticsValuePhotoSourceCamera
            case .PhotoLibrary: return OEXAnalyticsValuePhotoSourceLibrary
        }
    }
}

extension OEXAnalytics {
    
    func trackProfileViewed(username : String) {
        let event = OEXAnalyticsEvent()
        event.name = OEXAnalyticsEventProfileViewed
        event.displayName = "Viewed a profile"
        event.category = OEXAnalyticsCategoryProfile
        event.label = username
        
        self.trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackSetProfilePhoto(photoSource: AnaylticsPhotoSource) {
        let event = OEXAnalyticsEvent()
        event.name = OEXAnalyticsEventPictureSet
        event.displayName = "Set a profile picture"
        event.category = OEXAnalyticsCategoryProfile
        event.label = photoSource.value
        
        self.trackEvent(event, forComponent: nil, withInfo: nil)
    }
}
