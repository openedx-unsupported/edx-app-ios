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
    
    private func additionalParams(selectedRating: Int? = nil) -> [String: String] {
        var params = [key_app_version : Bundle.main.oex_buildVersionString()]
        if let rating = selectedRating{
            params[key_rating] = String(rating)
        }
        return params
    }
    
    private func appReviewEvent(name: String, displayName: String) -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = name
        event.displayName = displayName
        event.category = AnalyticsCategory.AppReviews.rawValue
        return event
    }

    func trackAppReviewScreen() {
        self.trackScreen(withName: AnalyticsScreenName.AppReviews.rawValue, courseID: nil, value: nil, additionalInfo: additionalParams(selectedRating: nil))
        
        self.trackEvent(appReviewEvent(name: AnalyticsEventName.ViewRating.rawValue, displayName: viewRatingDisplayName), forComponent: nil, withInfo: additionalParams())
    }
    
    func trackDismissRating() {
        self.trackEvent(appReviewEvent(name: AnalyticsEventName.DismissRating.rawValue, displayName: dismissRatingDisplayName), forComponent: nil, withInfo: additionalParams())
    }
    
    func trackSubmitRating(rating: Int) {
        self.trackEvent(appReviewEvent(name: AnalyticsEventName.SubmitRating.rawValue, displayName: submitRatingDisplayName), forComponent: nil, withInfo: additionalParams(selectedRating: rating))
    }
    
    func trackSendFeedback(rating: Int) {
        self.trackEvent(appReviewEvent(name: AnalyticsEventName.SendFeedback.rawValue, displayName: sendFeedbackDisplayName), forComponent: nil, withInfo: additionalParams(selectedRating: rating))
    }
    
    func trackMaybeLater(rating: Int) {
        self.trackEvent(appReviewEvent(name: AnalyticsEventName.MaybeLater.rawValue, displayName: maybeLaterDisplayName), forComponent: nil, withInfo: additionalParams(selectedRating: rating))
    }
    
    func trackRateTheApp(rating: Int) {
        self.trackEvent(appReviewEvent(name: AnalyticsEventName.RateTheApp.rawValue, displayName: rateTheAppDisplayName), forComponent: nil, withInfo: additionalParams(selectedRating: rating))
    }
}
