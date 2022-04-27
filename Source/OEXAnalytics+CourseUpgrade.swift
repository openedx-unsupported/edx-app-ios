//
//  OEXAnalytics+CourseUpgrade.swift
//  edX
//
//  Created by Saeed Bashir on 4/27/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation
extension OEXAnalytics {
    func trackUpgradeNow(with courseID: String, blockID: String? = nil, pacing: String, screenName: CourseUpgradeScreen, coursePrice: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.UpgradeNowClicked.rawValue
        event.name = AnalyticsEventName.UpgradeNowClicked.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screenName.text,
            key_course_id: courseID,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradePaymentTime(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, elapsedTime: Int) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradePaymentTime.rawValue
        event.name = AnalyticsEventName.CourseUpgradePaymentTime.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)",
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeTimeToLoadPrice(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, elapsedTime: Int) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeTimeToLoadPrice.rawValue
        event.name = AnalyticsEventName.CourseUpgradeTimeToLoadPrice.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)",
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradePaymentError(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, paymentError: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradePaymentError.rawValue
        event.name = AnalyticsEventName.CourseUpgradePaymentError.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.UpgradeError.rawValue: paymentError,
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeError(courseID: String, blockID: String, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, upgradeError: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeError.rawValue
        event.name = AnalyticsEventName.CourseUpgradeError.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.UpgradeError.rawValue: upgradeError,
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeLoadError(courseID: String, blockID: String? = nil, pacing: String, screen: CourseUpgradeScreen) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeLoadError.rawValue
        event.name = AnalyticsEventName.CourseUpgradeLoadError.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeErrorAction(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, errorAction: String, upgradeError: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeErrorAction.rawValue
        event.name = AnalyticsEventName.CourseUpgradeErrorAction.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.ErrorAction.rawValue: errorAction,
            AnalyticsEventDataKey.UpgradeError.rawValue: upgradeError,
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeSuccess(courseID: String, blockID: String? = nil, pacing: String, price: String, screen: CourseUpgradeScreen, elapsedTime: Int) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeSuccess.rawValue
        event.name = AnalyticsEventName.CourseUpgradeSuccess.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
            AnalyticsEventDataKey.Price.rawValue: price,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)",
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeDuration(isRefresh: Bool, courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, elapsedTime: Int) {
        let event = OEXAnalyticsEvent()
        event.displayName = isRefresh ? AnalyticsDisplayName.CourseUpgradeSuccessDurationAfterRefresh.rawValue : AnalyticsDisplayName.CourseUpgradeSuccessDuration.rawValue
        event.name = isRefresh ? AnalyticsEventName.CourseUpgradeSuccessDurationAfterRefresh.rawValue : AnalyticsEventName.CourseUpgradeSuccessDuration.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID ?? "",
            AnalyticsEventDataKey.ScreenName.rawValue: screen.text,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)",
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }
}
