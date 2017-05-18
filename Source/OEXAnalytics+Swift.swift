//
//  OEXAnalytics+Swift.swift
//  edX
//
//  Created by Akiva Leffert on 9/15/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

import Foundation

//New anayltics events go here:
public enum AnalyticsCategory : String {
    case Conversion = "conversion"
    case Discovery = "discovery"
    case AppReviews = "app-reviews"
}

public enum AnalyticsEventName: String {
    case CourseEnrollment = "edx.bi.app.course.enroll.clicked"
    case DiscoverCourses = "edx.bi.app.discover.courses.tapped"
    case ExploreSubjects = "edx.bi.app.discover.explore.tapped"
    case UserLogin = "edx.bi.app.user.login"
    case UserRegistration = "edx.bi.app.user.register.clicked"
    case ViewRating = "edx.bi.app.app_reviews.view_rating"
    case DismissRating = "edx.bi.app.app_reviews.dismiss_rating"
    case SubmitRating = "edx.bi.app.app_reviews.submit_rating"
    case SendFeedback = "edx.bi.app.app_reviews.send_feedback"
    case MaybeLater = "edx.bi.app.app_reviews.maybe_later"
    case RateTheApp = "edx.bi.app.app_reviews.rate_the_app"
}

public enum AnalyticsScreenName: String {
    case AppReviews = "AppReviews: View Rating"
}

extension OEXAnalytics {

    static func discoverCoursesEvent() -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.category = AnalyticsCategory.Discovery.rawValue
        event.name = AnalyticsEventName.DiscoverCourses.rawValue
        event.displayName = "Discover Courses"
        return event
    }

    static func exploreSubjectsEvent() -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.category = AnalyticsCategory.Discovery.rawValue
        event.name = AnalyticsEventName.ExploreSubjects.rawValue
        event.displayName = "Explore Courses"
        return event
    }

    @objc static func loginEvent() -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.UserLogin.rawValue
        event.displayName = "User Login"
        return event
    }

    @objc static func registerEvent() -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.UserRegistration.rawValue
        event.displayName = "Create Account Clicked"
        event.category = AnalyticsCategory.Conversion.rawValue
        event.label = "iOS v\(Bundle.main.oex_shortVersionString())"
        return event
    }

    @objc static func enrollEvent(courseId: String) -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.CourseEnrollment.rawValue
        event.displayName = "Enroll Course Clicked"
        event.category = AnalyticsCategory.Conversion.rawValue
        event.label = courseId
        return event
    }
}
