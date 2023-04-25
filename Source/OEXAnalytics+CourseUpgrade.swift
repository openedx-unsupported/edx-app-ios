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
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            AnalyticsEventDataKey.ScreenName.rawValue: screenName.rawValue,
            key_course_id: courseID,
            AnalyticsEventDataKey.Price.rawValue: coursePrice
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradePaymentTime(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, elapsedTime: Int) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradePaymentTime.rawValue
        event.name = AnalyticsEventName.CourseUpgradePaymentTime.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)"
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeTimeToLoadPrice(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, elapsedTime: Int) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeTimeToLoadPrice.rawValue
        event.name = AnalyticsEventName.CourseUpgradeTimeToLoadPrice.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)"
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradePaymentError(name: AnalyticsDisplayName, biName: AnalyticsEventName, courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, paymentError: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = name.rawValue
        event.name = biName.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.UpgradeError.rawValue: paymentError
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackCourseUpgradePaymentCancelError(name: AnalyticsDisplayName, biName: AnalyticsEventName, courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, paymentError: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradePaymentCancelError.rawValue
        event.name = AnalyticsEventName.CourseUpgradePaymentCancelError.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.Price.rawValue: coursePrice,
            AnalyticsEventDataKey.UpgradeError.rawValue: paymentError
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeError(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String? = nil, screen: CourseUpgradeScreen, upgradeError: String, flowType: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeError.rawValue
        event.name = AnalyticsEventName.CourseUpgradeError.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.UpgradeError.rawValue: upgradeError
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)
        info.setObjectOrNil(coursePrice, forKey: AnalyticsEventDataKey.Price.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeLoadError(courseID: String, blockID: String? = nil, pacing: String, screen: CourseUpgradeScreen) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeLoadError.rawValue
        event.name = AnalyticsEventName.CourseUpgradeLoadError.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeErrorAction(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String? = nil, screen: CourseUpgradeScreen, errorAction: String, upgradeError: String, flowType: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeErrorAction.rawValue
        event.name = AnalyticsEventName.CourseUpgradeErrorAction.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.ErrorAction.rawValue: errorAction,
            AnalyticsEventDataKey.UpgradeError.rawValue: upgradeError,
            AnalyticsEventDataKey.PaymentFlowType.rawValue: flowType
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)
        info.setObjectOrNil(coursePrice, forKey: AnalyticsEventDataKey.Price.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeSuccess(courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, elapsedTime: Int, flowType: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeSuccess.rawValue
        event.name = AnalyticsEventName.CourseUpgradeSuccess.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)",
            AnalyticsEventDataKey.PaymentFlowType.rawValue: flowType
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)
        info.setObjectOrNil(coursePrice, forKey: AnalyticsEventDataKey.Price.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeDuration(isRefresh: Bool, courseID: String, blockID: String? = nil, pacing: String, coursePrice: String, screen: CourseUpgradeScreen, elapsedTime: Int, flowType: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = isRefresh ? AnalyticsDisplayName.CourseUpgradeSuccessDurationAfterRefresh.rawValue : AnalyticsDisplayName.CourseUpgradeSuccessDuration.rawValue
        event.name = isRefresh ? AnalyticsEventName.CourseUpgradeSuccessDurationAfterRefresh.rawValue : AnalyticsEventName.CourseUpgradeSuccessDuration.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        var info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.ElapsedTime.rawValue: "\(elapsedTime)",
            AnalyticsEventDataKey.PaymentFlowType.rawValue: flowType
        ]

        info.setObjectOrNil(blockID, forKey: AnalyticsEventDataKey.ComponentID.rawValue)
        info.setObjectOrNil(coursePrice, forKey: AnalyticsEventDataKey.Price.rawValue)

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUnfulfilledPurchaseInitiated(courseID: String, pacing: String, screen: CourseUpgradeScreen, flowType: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeUnfulfilledPurchaseInitiated.rawValue
        event.name = AnalyticsEventName.CourseUpgradeUnfulfilledPurchaseInitiated.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.PaymentFlowType.rawValue: flowType,
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUpgradeNewEexperienceAlertAction(courseID: String, pacing: String, screen: CourseUpgradeScreen, flowType: String, action: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeNewEexperienceAlertAction.rawValue
        event.name = AnalyticsEventName.CourseUpgradeNewEexperienceAlertAction.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID,
            AnalyticsEventDataKey.ScreenName.rawValue: screen.rawValue,
            AnalyticsEventDataKey.PaymentFlowType.rawValue: flowType,
            AnalyticsEventDataKey.Action.rawValue: action
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackRestorePurchaseClicked() {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeRestorePurchaseClicked.rawValue
        event.name = AnalyticsEventName.CourseUpgradeRestorePurchaseClicked.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        trackEvent(event, forComponent: nil, withInfo: nil)
    }

    func trackRestoreSuccessAlertAction(action: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseUpgradeRestoreSuccessAlertAction.rawValue
        event.name = AnalyticsEventName.CourseUpgradeRestoreSuccessAlertAction.rawValue
        event.category = AnalyticsCategory.InAppPurchases.rawValue

        trackEvent(event, forComponent: nil, withInfo: [AnalyticsEventDataKey.Action.rawValue: action])
    }
}
