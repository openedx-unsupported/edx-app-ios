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
    case WhatsNew = "whats-new"
}

public enum AnalyticsDisplayName : String {
    case DiscoverCourses = "Discover Courses"
    case ExploreCourses = "Explore Courses"
    case UserLogin = "User Login"
    case CreateAccount = "Create Account Clicked"
    case RegistrationSuccess = "Registration Success"
    case EnrolledCourseClicked = "Course Enroll Clicked"
    case EnrolledCourseSuccess = "Course Enroll Success"
    case BulkDownloadToggleOn = "Bulk Download Toggle On"
    case BulkDownloadToggleOff = "Bulk Download Toggle Off"
}

public enum AnalyticsEventName: String {
    case CourseEnrollmentClicked = "edx.bi.app.course.enroll.clicked"
    case CourseEnrollmentSuccess = "edx.bi.app.course.enroll.success"
    case DiscoverCourses = "edx.bi.app.discover.courses.tapped"
    case ExploreSubjects = "edx.bi.app.discover.explore.tapped"
    case UserLogin = "edx.bi.app.user.login"
    case UserRegistrationClick = "edx.bi.app.user.register.clicked"
    case UserRegistrationSuccess = "edx.bi.app.user.register.success"
    case ViewRating = "edx.bi.app.app_reviews.view_rating"
    case DismissRating = "edx.bi.app.app_reviews.dismiss_rating"
    case SubmitRating = "edx.bi.app.app_reviews.submit_rating"
    case SendFeedback = "edx.bi.app.app_reviews.send_feedback"
    case MaybeLater = "edx.bi.app.app_reviews.maybe_later"
    case RateTheApp = "edx.bi.app.app_reviews.rate_the_app"
    case WhatsNewClose = "edx.bi.app.whats_new.close"
    case WhatsNewDone = "edx.bi.app.whats_new.done"
    case VideosSubsectionDelete = "edx.bi.app.video.delete.subsection"
    case VideosUnitDelete = "edx.bi.app.video.delete.unit"
    case BulkDownloadToggleOn = "edx.bi.app.videos.download.toggle.on"
    case BulkDownloadToggleOff = "edx.bi.app.videos.download.toggle.off"
}

public enum AnalyticsScreenName: String {
    case AppReviews = "AppReviews: View Rating"
    case CourseDates = "Course Dates"
    case WhatsNew = "WhatsNew: Whats New"
    case ViewTopicThreads = "Forum: View Topic Threads"
    case CreateTopicThread = "Forum: Create Topic Thread"
    case ViewThread = "Forum: View Thread"
    case AddThreadResponse = "Forum: Add Thread Response"
    case AddResponseComment = "Forum: Add Response Comment"
    case ViewResponseComments = "Forum: View Response Comments"
    case CourseVideos = "Videos: Course Videos"
}

public enum AnalyticsEventDataKey: String {
    case ThreadID = "thread_id"
    case TopicID = "topic_id"
    case ResponseID = "response_id"
    case Author = "author"
    case SubsectionID = "subsection_id"
    case UnitID = "unit_id"
    case totalDownloadableVideos = "total_downloadable_videos"
    case remainingDownloadableVideos = "remaining_downloadable_videos"
}


extension OEXAnalytics {

    static func discoverCoursesEvent() -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.category = AnalyticsCategory.Discovery.rawValue
        event.name = AnalyticsEventName.DiscoverCourses.rawValue
        event.displayName = AnalyticsDisplayName.DiscoverCourses.rawValue
        return event
    }

    static func exploreSubjectsEvent() -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.category = AnalyticsCategory.Discovery.rawValue
        event.name = AnalyticsEventName.ExploreSubjects.rawValue
        event.displayName = AnalyticsDisplayName.ExploreCourses.rawValue
        return event
    }

    @objc static func loginEvent() -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.UserLogin.rawValue
        event.displayName = AnalyticsDisplayName.UserLogin.rawValue
        return event
    }
    
    @objc static func registerEvent(name: String, displayName: String) -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = name
        event.displayName = displayName
        event.category = AnalyticsCategory.Conversion.rawValue
        event.label = "iOS v\(Bundle.main.oex_shortVersionString())"
        return event
    }
    
    func trackCourseEnrollment(courseId: String, name: String, displayName: String) {
        let event = OEXAnalyticsEvent()
        event.name = name
        event.displayName = displayName
        event.category = AnalyticsCategory.Conversion.rawValue
        event.label = courseId

        trackEvent(event, forComponent: nil, withInfo: [:])
    }

    func trackDiscussionScreen(
            withName: AnalyticsScreenName,
            courseId: String,
            value: String?,
            threadId: String?,
            topicId: String?,
            responseID: String?,
            author: String? = String?.none) {
        
        var info: [String:String] = [:]
        info.setObjectOrNil(threadId, forKey: AnalyticsEventDataKey.ThreadID.rawValue)
        info.setObjectOrNil(topicId, forKey: AnalyticsEventDataKey.TopicID.rawValue)
        info.setObjectOrNil(responseID, forKey: AnalyticsEventDataKey.ResponseID.rawValue)
        info.setObjectOrNil(author, forKey: AnalyticsEventDataKey.Author.rawValue)
        self.trackScreen(withName: withName.rawValue, courseID: courseId, value: value, additionalInfo: info)
    }
    
    func trackSubsectionDeleteVideos(courseID: String, subsectionID: String){
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = AnalyticsEventName.VideosSubsectionDelete.rawValue
        event.displayName = "Videos: Subsection Delete"
        
        trackEvent(event, forComponent: nil, withInfo: [AnalyticsEventDataKey.SubsectionID.rawValue : subsectionID])
    }
    
    func trackBulkDownloadToggle(isOn: Bool, courseID: String, totalVideosCount: Int, remainingVideosCount: Int) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = isOn ? AnalyticsEventName.BulkDownloadToggleOn.rawValue : AnalyticsEventName.BulkDownloadToggleOff.rawValue
        event.displayName = isOn ? AnalyticsDisplayName.BulkDownloadToggleOn.rawValue : AnalyticsDisplayName.BulkDownloadToggleOff.rawValue
        
        var info: [String:String] = [ key_course_id : courseID, AnalyticsEventDataKey.totalDownloadableVideos.rawValue : "\(totalVideosCount)", key_component:"downloadmodule" ]
        
        if isOn {
            info[AnalyticsEventDataKey.remainingDownloadableVideos.rawValue] = "\(remainingVideosCount)"
        }
        
        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackUnitDeleteVideo(courseID: String, unitID: String) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = AnalyticsEventName.VideosUnitDelete.rawValue
        event.displayName = "Videos: Unit Delete"
        
        trackEvent(event, forComponent: nil, withInfo: [AnalyticsEventDataKey.UnitID.rawValue : unitID])
    }
}
