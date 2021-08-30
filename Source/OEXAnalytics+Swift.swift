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
    case SocialSharing = "social-sharing"
    case CourseDates = "course_dates"
}

public enum AnalyticsDisplayName : String {
    case AccountSettings = "Account Settings"
    case DiscoverCourses = "Discover Courses"
    case ExploreCourses = "Explore Courses"
    case UserLogin = "User Login"
    case ValuePropModalView = "Value Prop Modal View"
    case ValuePropLearnMoreClicked = "Value Prop Learn More Clicked"
    case ValuePropLockedContentClicked = "Value Prop Locked Content Clicked"
    case ValuePropShowMoreClicked = "Value Prop Show More Clicked"
    case ValuePropShowLessClicked = "Value Prop Show Less Clicked"
    case CreateAccount = "Create Account Clicked"
    case RegistrationSuccess = "Registration Success"
    case EnrolledCourseClicked = "Course Enroll Clicked"
    case EnrolledCourseSuccess = "Course Enroll Success"
    case BulkDownloadToggleOn = "Bulk Download Toggle On"
    case BulkDownloadToggleOff = "Bulk Download Toggle Off"
    case SharedCourse = "Shared a course"
    case SubjectsDiscovery = "Subject Discovery"
    case CourseSearch = "Discovery: Courses Search"
    case ChromecastConnected = "Cast: Connected"
    case ChromecastDisonnected = "Cast: Disconnected"
    case CourseDatesBanner = "PLS Banner Viewed"
    case CourseDatesShiftButtonTapped = "PLS Shift Button Tapped"
    case CourseDatesShift = "PLS Shift Dates"
    case CelebrationModalSocialShareClicked =  "Celebration: Social Share Clicked"
    case CelebrationModalView =  "Celebration: First Section Opened"
    case CourseComponentTapped = "Dates: Course Component Tapped"
    case CourseUnsupportedComponentTapped = "Dates: Unsupported Component Tapped"
    case ExploreAllCourses = "Explore All Courses"
    case MyPrograms = "My Programs"
    case ResumeCourseTapped = "Resume Course Tapped"
    case CalendarToggleOn = "Dates: Calendar Toggle On"
    case CalendarToggleOff = "Dates: Calendar Toggle Off"
    case CalendarAccessAllowed = "Dates: Calendar Access Allowed"
    case CalendarAccessDontAllow = "Dates: Calendar Access Dont Allow"
    case CalendarAddDates = "Dates: Calendar Add Dates"
    case CalendarAddCancelled = "Dates: Calendar Add Cancelled"
    case CalendarAddConfirmation = "Dates: Calendar Add Confirmation"
    case CalendarViewEvents = "Dates: Calendar View Events"
    case CalendarAddDatesSuccess = "Dates: Calendar Add Dates Success"
    case CalendarRemoveDatesSuccess = "Dates: Calendar Remove Dates Success"
    case CalendarRemoveDatesOK = "Dates: Calendar Remove Dates"
    case CalendarRemoveDatesCancelled = "Dates: Calendar Remove Cancelled"
    case CalendarUpdateDatesSuccess = "Dates: Calendar Update Dates Success"
    case CalendarSyncUpdateDates = "Dates: Calendar Sync Update Dates"
    case CalendarSyncRemoveCalendar = "Dates: Calendar Sync Remove Calendar"
    case SubsectionViewOnWebTapped = "Subsection View On Web Tapped"
    case OpenInBrowserBannerDisplayed = "Open in Browser Banner Displayed"
    case OpenInBrowserBannerTapped = "Open in Browser Banner Tapped"
    case UpgradeNowClicked = "Upgrade Now Clicked"
    case ProfilePageView = "Profile Page View"
    case PersonalInformationClicked = "Personal Information Clicked"
    case FAQClicked = "FAQ Clicked"
    case WifiOn = "Wifi On"
    case WifiOff = "Wifi Off"
    case WifiAllow = "Wifi Allow"
    case WifiDontAllow = "Wifi Dont Allow"
    case EmailSupportClicked = "Email Support Clicked"
    case ProfileVideoDownloadQualityClicked = "Profile: Video Download Quality Clicked"
    case CourseVideosDownloadQualityClicked = "Course Videos: Video Download Quality Clicked"
    case VideoDownloadQuality = "Video Download Quality"
    case VideoDownloadQualityChanged = "Video Download Quality Changed"
}

public enum AnalyticsEventName: String {
    case CourseEnrollmentClicked = "edx.bi.app.course.enroll.clicked"
    case CourseEnrollmentSuccess = "edx.bi.app.course.enroll.success"
    case DiscoverCourses = "edx.bi.app.discover.courses.tapped"
    case ExploreSubjects = "edx.bi.app.discover.explore.tapped"
    case UserLogin = "edx.bi.app.user.login"
    case UserRegistrationClick = "edx.bi.app.user.register.clicked"
    case UserRegistrationSuccess = "edx.bi.app.user.register.success"
    case ValuePropLearnMoreClicked = "edx.bi.app.value.prop.learn.more.clicked"
    case ValuePropLockedContentClicked = "edx.bi.app.course.unit.locked.content.clicked"
    case ValuePropShowMoreClicked = "edx.bi.app.value_prop.show_more.clicked"
    case ValuePropShowLessClicked = "edx.bi.app.value_prop.show_less.clicked"
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
    case SharedCourse = "edx.bi.app.course.shared"
    case SubjectClicked = "edx.bi.app.discover.subject.clicked"
    case CourseSearch = "edx.bi.app.discovery.courses_search"
    case ChromecastConnected = "edx.bi.app.cast.connected"
    case ChromecastDisconnected = "edx.bi.app.cast.disconnected"
    case CourseDatesInfo = "edx.bi.app.coursedates.info"
    case CourseDatesUpgradeToParticipate = "edx.bi.app.coursedates.upgrade.participate"
    case CourseDatesUpgradeToShift = "edx.bi.app.coursedates.upgrade.shift"
    case CourseDatesShiftDates = "edx.bi.app.coursedates.shift"
    case CelebrationModalSocialShareClicked =  "edx.ui.lms.celebration.social_share.clicked"
    case CelebrationModalView =  "edx.ui.lms.celebration.first_section.opened"
    case CourseComponentTapped = "edx.bi.app.coursedates.component.tapped"
    case CourseUnsupportedComponentTapped = "edx.bi.app.coursedates.unsupported.component.tapped"
    case ExploreAllCourses = "edx.bi.app.discovery.explore.all.courses"
    case ResumeCourseTapped = "edx.bi.app.course.resume.tapped"
    case CalendarToggleOn = "edx.bi.app.calendar.toggle_on"
    case CalendarToggleOff = "edx.bi.app.calendar.toggle_off"
    case CalendarAccessAllowed = "edx.bi.app.calendar.access_ok"
    case CalendarAccessDontAllow = "edx.bi.app.calendar.access_dont_allow"
    case CalendarAddDates = "edx.bi.app.calendar.add_ok"
    case CalendarAddCancelled = "edx.bi.app.calendar.add_cancel"
    case CalendarAddConfirmation = "edx.bi.app.calendar.confirmation_done"
    case CalendarViewEvents = "edx.bi.app.calendar.confirmation_view_events"
    case CalendarAddDatesSuccess = "edx.bi.app.calendar.add_success"
    case CalendarRemoveDatesSuccess = "edx.bi.app.calendar.remove_success"
    case CalendarRemoveDatesOK = "edx.bi.app.calendar.remove_ok"
    case CalendarRemoveDatesCancelled = "edx.bi.app.calendar.remove_cancel"
    case CalendarUpdateDatesSuccess = "edx.bi.app.calendar.update_success"
    case CalendarSyncUpdateDates = "edx.bi.app.calendar.sync_update"
    case CalendarSyncRemoveCalendar = "edx.bi.app.calendar.sync_remove"
    case SubsectionViewOnWebTapped = "edx.bi.app.course.subsection.view_on_web.tapped"
    case OpenInBrowserBannerDisplayed = "edx.bi.app.navigation.component.open_in_browser_banner.displayed"
    case OpenInBrowserBannerTapped = "edx.bi.app.navigation.component.open_in_browser_banner.tapped"
    case UpgradeNowClicked = "edx.bi.app.upgrade.button.clicked"
    case PersonalInformationClicked = "edx.bi.app.profile.personal_info.clicked"
    case FAQClicked = "edx.bi.app.profile.faq.clicked"
    case WifiOn = "edx.bi.app.profile.wifi.switch.on"
    case WifiOff = "edx.bi.app.profile.wifi.switch.off"
    case WifiAllow = "edx.bi.app.profile.wifi.allow"
    case WifiDontAllow = "edx.bi.app.profile.wifi.dont_allow"
    case EmailSupportClicked = "edx.bi.app.profile.email_support.clicked"
    case ProfileVideoDownloadQualityClicked = "edx.bi.app.profile.video_download_quality.clicked"
    case CourseVideosDownloadQualityClicked = "edx.bi.app.course_videos.video_download_quality.clicked"
    case VideoDownloadQualityChanged = "edx.bi.app.video_download_quality.changed"
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
    case SubjectsDiscovery = "Discover: All Subjects"
    case DiscoverProgram = "Find Programs"
    case DiscoverDegree = "Find Degrees"
    case ProgramInfo = "Program Info"
    case CourseEnrollment = "course_enrollment"
    case CourseUnit = "course_unit"
    case CourseDashboard = "course_dashboard"
    case DatesScreen = "dates_screen"
    case AssignmentScreen = "assignments_screen"
    case SpecialExamBlockedScreen = "Special Exam Blocked Screen"
    case EmptySectionOutline = "Empty Section Outline"
    case Profile = "profile"
    case VideoDownloadQuality = "Video Download Quality"
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
    case UserID = "user_id"
    case SubjectID = "subject_id"
    case PlayMediumYoutube = "youtube"
    case PlayMediumChromecast = "google_cast"
    case AssignmentID = "assignment_id"
    case CourseMode = "mode"
    case ScreenName = "screen_name"
    case BannerEventType = "banner_type"
    case Success = "success"
    case Service = "service"
    case BlockType = "block_type"
    case Link = "link"
    case Pacing = "pacing"
    case UserType = "user_type"
    case SyncReason = "sync_reason"
    case SpecialExamInfo = "special_exam_info"
    case ComponentID = "component_id"
    case ComponentType = "component_type"
    case OpenedURL = "opened_url"
    case Value = "value"
    case OldValue = "old_value"
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
    
    func trackBulkDownloadToggle(isOn: Bool, courseID: String, totalVideosCount: Int, remainingVideosCount: Int, blockID: CourseBlockID?) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = isOn ? AnalyticsEventName.BulkDownloadToggleOn.rawValue : AnalyticsEventName.BulkDownloadToggleOff.rawValue
        event.displayName = isOn ? AnalyticsDisplayName.BulkDownloadToggleOn.rawValue : AnalyticsDisplayName.BulkDownloadToggleOff.rawValue
        
        var info: [String:String] = [ key_course_id : courseID, AnalyticsEventDataKey.totalDownloadableVideos.rawValue : "\(totalVideosCount)", key_component:"downloadmodule" ]
        
        if isOn {
            info[AnalyticsEventDataKey.remainingDownloadableVideos.rawValue] = "\(remainingVideosCount)"
        }
        if let blockID = blockID {
            info[OEXAnalyticsKeyBlockID] = "\(blockID)"
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

    func trackCourseShared(courseID: String, url: String, type: String) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID;
        event.name = AnalyticsEventName.SharedCourse.rawValue
        event.displayName = AnalyticsDisplayName.SharedCourse.rawValue
        event.category = AnalyticsCategory.SocialSharing.rawValue
        trackEvent(event, forComponent: nil, withInfo: ["url": url, "type": type])
    }
    
    func trackCourseCelebrationSocialShareClicked(courseID: String, type: String) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = AnalyticsEventName.CelebrationModalSocialShareClicked.rawValue
        event.displayName = AnalyticsDisplayName.CelebrationModalSocialShareClicked.rawValue
        trackEvent(event, forComponent: nil, withInfo: [AnalyticsEventDataKey.Service.rawValue: type])
    }
    
    func trackCourseCelebrationFirstSection(courseID: String) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = AnalyticsEventName.CelebrationModalView.rawValue
        event.displayName = AnalyticsDisplayName.CelebrationModalView.rawValue
        trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackSubjectDiscovery(subjectID: String) {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.SubjectClicked.rawValue
        event.displayName = AnalyticsDisplayName.SubjectsDiscovery.rawValue
        event.category = AnalyticsCategory.Discovery.rawValue
        
        trackEvent(event, forComponent: nil, withInfo: [ AnalyticsEventDataKey.SubjectID.rawValue : subjectID ])
    }

    func trackCourseSearch(search query: String, action: String) {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.CourseSearch.rawValue
        event.displayName = AnalyticsDisplayName.CourseSearch.rawValue
        event.category = AnalyticsCategory.Discovery.rawValue
        event.label = query
        trackEvent(event, forComponent: nil, withInfo: ["action": action, "app_version": Bundle.main.oex_buildVersionString()])
    }
    
    func trackChromecastConnected() {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.ChromecastConnected.rawValue
        event.displayName = AnalyticsDisplayName.ChromecastConnected.rawValue
        trackEvent(event, forComponent: nil, withInfo: [key_play_medium: AnalyticsEventDataKey.PlayMediumChromecast.rawValue])
    }
    
    func trackChromecastDisconnected() {
        let event = OEXAnalyticsEvent()
        event.name = AnalyticsEventName.ChromecastDisconnected.rawValue
        event.displayName = AnalyticsDisplayName.ChromecastDisonnected.rawValue
        trackEvent(event, forComponent: nil, withInfo: [key_play_medium: AnalyticsEventDataKey.PlayMediumChromecast.rawValue])
    }
    
    func trackValuePropLearnMore(courseID: String, screenName: AnalyticsScreenName, assignmentID: String? = nil) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = AnalyticsEventName.ValuePropLearnMoreClicked.rawValue
        event.displayName = AnalyticsDisplayName.ValuePropLearnMoreClicked.rawValue
        
        var info: [String:String] = [:]
        info.setObjectOrNil(screenName.rawValue, forKey: AnalyticsEventDataKey.ScreenName.rawValue)
        if assignmentID != nil {
            info.setObjectOrNil(assignmentID, forKey: AnalyticsEventDataKey.AssignmentID.rawValue)
        }
        
        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackLockedContentClicked(courseID: String, screenName: AnalyticsScreenName, assignmentID: String) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.name = AnalyticsEventName.ValuePropLockedContentClicked.rawValue
        event.displayName = AnalyticsDisplayName.ValuePropLockedContentClicked.rawValue
        
        var info: [String:String] = [:]
        info.setObjectOrNil(screenName.rawValue, forKey: AnalyticsEventDataKey.ScreenName.rawValue)
        info.setObjectOrNil(assignmentID, forKey: AnalyticsEventDataKey.AssignmentID.rawValue)
        
        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackValuePropModal(with name: AnalyticsScreenName, courseId: String, assignmentID: String? = nil) {
        var info: [String:String] = [:]
        if assignmentID != nil {
            info.setObjectOrNil(assignmentID, forKey: AnalyticsEventDataKey.AssignmentID.rawValue)
        }
        info.setSafeObject(name.rawValue, forKey: AnalyticsEventDataKey.ScreenName.rawValue)
        
        trackScreen(withName: AnalyticsDisplayName.ValuePropModalView.rawValue, courseID: courseId, value: nil, additionalInfo: info)
    }

    func trackValuePropShowMoreless(with displayName: AnalyticsDisplayName, eventName: AnalyticsEventName, courseID: String, blockID: String, pacing: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = displayName.rawValue
        event.name = eventName.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID,
            key_course_id: courseID
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackDatesBannerAppearence(screenName: AnalyticsScreenName, courseMode: String, eventName: String, bannerType: String) {
        let event = OEXAnalyticsEvent()
        event.name = eventName
        event.displayName = AnalyticsDisplayName.CourseDatesBanner.rawValue
        event.category = AnalyticsCategory.CourseDates.rawValue
        
        let info: [AnyHashable: Any] = [
            AnalyticsEventDataKey.CourseMode.rawValue: courseMode,
            AnalyticsEventDataKey.ScreenName.rawValue: screenName.rawValue,
            AnalyticsEventDataKey.BannerEventType.rawValue: bannerType
        ]
        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackDatesShiftButtonTapped(screenName: AnalyticsScreenName, courseMode: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseDatesShiftButtonTapped.rawValue
        event.category = AnalyticsCategory.CourseDates.rawValue
        
        let info = [
            AnalyticsEventDataKey.CourseMode.rawValue: courseMode,
            AnalyticsEventDataKey.ScreenName.rawValue: screenName.rawValue
        ]
        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackDatesShiftEvent(screenName: AnalyticsScreenName, courseMode: String, success: Bool) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseDatesShift.rawValue
        event.category = AnalyticsCategory.CourseDates.rawValue
        
        let info:[String : Any] = [
            AnalyticsEventDataKey.CourseMode.rawValue: courseMode,
            AnalyticsEventDataKey.ScreenName.rawValue: screenName.rawValue,
            AnalyticsEventDataKey.Success.rawValue: success
        ]
        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseComponentTapped(courseID: String, blockID: String, blockType: String, link: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.CourseComponentTapped.rawValue
        event.category = AnalyticsCategory.CourseDates.rawValue
        event.name = AnalyticsEventName.CourseComponentTapped.rawValue

        let info: [String: Any] = [
            OEXAnalyticsKeyBlockID: blockID,
            AnalyticsEventDataKey.BlockType.rawValue: blockType,
            AnalyticsEventDataKey.Link.rawValue: link,
            key_course_id:courseID
        ]
        
        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackCourseUnsupportedComponentTapped(courseID: String, blockID: String, link: String) {
        let event = OEXAnalyticsEvent()
        event.courseID = courseID
        event.displayName = AnalyticsDisplayName.CourseUnsupportedComponentTapped.rawValue
        event.category = AnalyticsCategory.CourseDates.rawValue
        event.name = AnalyticsEventName.CourseUnsupportedComponentTapped.rawValue

        let info: [String: Any] = [
            OEXAnalyticsKeyBlockID: blockID,
            AnalyticsEventDataKey.Link.rawValue: link,
            key_course_id:courseID
        ]
        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackExploreAllCourses() {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.ExploreAllCourses.rawValue
        event.name = AnalyticsEventName.ExploreAllCourses.rawValue
        event.category = OEXAnalyticsCategoryUserEngagement
        event.label = AnalyticsCategory.Discovery.rawValue

        trackEvent(event, forComponent: nil, withInfo: ["action":"landing_screen","app_version": Bundle.main.oex_buildVersionString()])
    }

    func trackResumeCourseTapped(courseID: String, blockID: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.ResumeCourseTapped.rawValue
        event.name = AnalyticsEventName.ResumeCourseTapped.rawValue
        event.category = OEXAnalyticsCategoryNavigation

        trackEvent(event, forComponent: nil, withInfo: [key_course_id: courseID, OEXAnalyticsKeyBlockID: blockID])
    }
    
    func trackCalendarEvent(displayName: AnalyticsDisplayName, eventName: AnalyticsEventName, userType: String, pacing: String, courseID: String, syncReason: String? = nil) {
        let event = OEXAnalyticsEvent()
        event.displayName = displayName.rawValue
        event.name = eventName.rawValue
        
        var info = [
            AnalyticsEventDataKey.UserType.rawValue: userType,
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            key_course_id: courseID
        ]
        
        info.setObjectOrNil(syncReason, forKey: AnalyticsEventDataKey.SyncReason.rawValue)
        
        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackSubsectionViewOnWebTapped(isSpecialExam: Bool, courseID: CourseBlockID, subsectionID: CourseBlockID) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsEventName.SubsectionViewOnWebTapped.rawValue
        event.name = AnalyticsEventName.SubsectionViewOnWebTapped.rawValue
        
        let info: [String : Any] = [
            key_course_id: courseID,
            AnalyticsEventDataKey.SpecialExamInfo.rawValue: isSpecialExam,
            AnalyticsEventDataKey.SubsectionID.rawValue: subsectionID
        ]
        
        trackEvent(event, forComponent: nil, withInfo: info)
    }

    func trackOpenInBrowserBannerEvent(displayName: AnalyticsDisplayName, eventName: AnalyticsEventName, userType: String, courseID: String, componentID: String, componentType: String, openURL: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = displayName.rawValue
        event.name = eventName.rawValue

        let info = [
            AnalyticsEventDataKey.UserType.rawValue: userType,
            AnalyticsEventDataKey.ComponentType.rawValue: componentType,
            AnalyticsEventDataKey.ComponentID.rawValue: componentID,
            AnalyticsEventDataKey.OpenedURL.rawValue: openURL,
            key_course_id: courseID
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackUpgradeNow(with courseID: String, blockID: String, pacing: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.UpgradeNowClicked.rawValue
        event.name = AnalyticsEventName.UpgradeNowClicked.rawValue

        let info = [
            AnalyticsEventDataKey.Pacing.rawValue: pacing,
            AnalyticsEventDataKey.ComponentID.rawValue: blockID,
            key_course_id: courseID
        ]

        trackEvent(event, forComponent: nil, withInfo: info)
    }
    
    func trackProfileOptionClcikEvent(displayName: AnalyticsDisplayName, name: AnalyticsEventName) {
        let event = OEXAnalyticsEvent()
        event.displayName = displayName.rawValue
        event.name = name.rawValue
        
        trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackWifi(isOn: Bool) {
        let event = OEXAnalyticsEvent()
        event.displayName = isOn ? AnalyticsDisplayName.WifiOn.rawValue : AnalyticsDisplayName.WifiOff.rawValue
        event.name = isOn ? AnalyticsEventName.WifiOn.rawValue : AnalyticsEventName.WifiOff.rawValue
        
        trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackWifi(allowed: Bool) {
        let event = OEXAnalyticsEvent()
        event.displayName = allowed ? AnalyticsDisplayName.WifiAllow.rawValue : AnalyticsDisplayName.WifiDontAllow.rawValue
        event.name = allowed ? AnalyticsEventName.WifiAllow.rawValue : AnalyticsEventName.WifiDontAllow.rawValue
        
        trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackVideoDownloadQualityClicked(displayName: AnalyticsDisplayName, name: AnalyticsEventName) {
        let event = OEXAnalyticsEvent()
        event.displayName = displayName.rawValue
        event.name = name.rawValue
                
        trackEvent(event, forComponent: nil, withInfo: nil)
    }
    
    func trackVideoDownloadQualityChanged(value: String, oldValue: String) {
        let event = OEXAnalyticsEvent()
        event.displayName = AnalyticsDisplayName.VideoDownloadQualityChanged.rawValue
        event.name = AnalyticsEventName.VideoDownloadQualityChanged.rawValue
        
        let info = [
            AnalyticsEventDataKey.Value.rawValue: value,
            AnalyticsEventDataKey.OldValue.rawValue: oldValue
        ]
        
        trackEvent(event, forComponent: nil, withInfo: info)
    }
}

