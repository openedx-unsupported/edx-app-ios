//
//  OEXAnalytics+Profiles.swift
//  edX
//
//  Created by Michael Katz on 10/26/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private enum ProfileAnalyticsEvent : String {
    case ProfileViewed = "edx.bi.app.profile.view"
    case PictureSet = "edx.bi.app.profile.setphoto"
}

private let OEXAnalyticsCategoryProfile = "profiles"

enum AnaylticsPhotoSource : String {
    case Camera = "camera"
    case PhotoLibrary = "library"
}

extension OEXAnalytics {
    
    func trackProfileViewed(username : String) {
        let event = OEXAnalyticsEvent()
        event.name = ProfileAnalyticsEvent.ProfileViewed.rawValue
        event.displayName = "Viewed a profile"
        event.category = OEXAnalyticsCategoryProfile
        event.label = username
        
        self.trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackSetProfilePhoto(photoSource: AnaylticsPhotoSource) {
        let event = OEXAnalyticsEvent()
        event.name = ProfileAnalyticsEvent.PictureSet.rawValue
        event.displayName = "Set a profile picture"
        event.category = OEXAnalyticsCategoryProfile
        event.label = photoSource.rawValue
        
        self.trackEvent(event, forComponent: nil, withInfo: nil)
    }
}
