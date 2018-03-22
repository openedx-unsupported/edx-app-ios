//
//  OEXAnayltics+Certificates.swift
//  edX
//
//  Created by Michael Katz on 11/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation


extension OEXAnalytics {

    func trackCertificateShared(url: String, type: String) {
        let event = OEXAnalyticsEvent()
        event.name = OEXAnalyticsEventCertificateShared
        event.displayName = "Shared a certificate"
        event.category = AnalyticsCategory.SocialSharing.rawValue

        let info = ["url" : url, "type": type]

        self.trackEvent(event, forComponent: nil, withInfo: info)
    }

}
