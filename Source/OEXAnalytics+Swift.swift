//
//  OEXAnalytics+Swift.swift
//  edX
//
//  Created by Akiva Leffert on 9/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

extension OEXAnalytics {
    
    func trackOutlineModeChanged(mode : CourseOutlineMode) {
        let event = OEXAnalyticsEvent()
        event.name = OEXAnalyticsEventOutlineModeChanged
        event.displayName = "Switch outline mode"
        event.category = OEXAnalyticsCategoryNavigation
        
        let modeValue : String
        
        switch mode {
        case .Full:
            modeValue = OEXAnalyticsValueNavigationModeFull
            event.label = "Switch to Full Mode"
        case .Video:
            modeValue = OEXAnalyticsValueNavigationModeVideo
            event.label = "Switch to Video Mode"
        }
        let info = [OEXAnalyticsKeyNavigationMode : modeValue]
        self.trackEvent(event, forComponent: nil, withInfo: info)
    }
    
}