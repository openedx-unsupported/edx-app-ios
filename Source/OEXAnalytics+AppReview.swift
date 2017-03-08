//
//  OEXAnalytics+AppReview.swift
//  edX
//
//  Created by Danial Zahid on 3/8/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

private let viewRatingDisplayName = "AppReviews: View Rating"
private let dismissRatingDisplayName = "AppReviews: Dismiss Rating"
private let submitRatingDisplayName = "AppReviews: Submit Rating"
private let sendFeedbackDisplayName = "AppReviews: Send Feedback"
private let maybeLaterDisplayName = "AppReviews: Maybe Later"
private let rateTheAppDisplayName = "AppReviews: Rate The App"

extension OEXAnalytics {
    
    private func additionalParams(rating: Int?) -> [String: String] {
        var params = [key_app_version : NSBundle.mainBundle().oex_buildVersionString()]
        if rating != nil{
            params[key_rating] = String(rating)
        }
        return params
    }
    
    private func appReviewEvent(name: String, displayName: String) -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = name
        event.displayName = displayName
        event.category = OEXAnalyticsCategoryAppReviews
        return event
    }

    func trackAppReviewScreen() {
        self.trackScreenWithName(OEXAnalyticsScreenAppReviews, courseID: nil, value: nil, additionalInfo: additionalParams(nil))
        
        self.trackEvent(appReviewEvent(OEXAnalyticsScreenAppReviews, displayName: viewRatingDisplayName), forComponent: nil, withInfo: additionalParams(nil))
    }
    
    func trackDismissRating() {
        self.trackEvent(appReviewEvent(OEXAnalyticsEventDismissRating, displayName: dismissRatingDisplayName), forComponent: nil, withInfo: additionalParams(nil))
    }
    
    func trackSubmitRating(rating: Int) {
        self.trackEvent(appReviewEvent(OEXAnalyticsEventSubmitRating, displayName: submitRatingDisplayName), forComponent: nil, withInfo: additionalParams(rating))
    }
    
    func trackSendFeedback(rating: Int) {
        self.trackEvent(appReviewEvent(OEXAnalyticsEventSendFeedback, displayName: sendFeedbackDisplayName), forComponent: nil, withInfo: additionalParams(rating))
    }
    
    func trackMaybeLater(rating: Int) {
        self.trackEvent(appReviewEvent(OEXAnalyticsEventMaybeLater, displayName: maybeLaterDisplayName), forComponent: nil, withInfo: additionalParams(rating))
    }
    
    func trackRateTheApp(rating: Int) {
        self.trackEvent(appReviewEvent(OEXAnalyticsEventRateTheApp, displayName: rateTheAppDisplayName), forComponent: nil, withInfo: additionalParams(rating))
    }
}
