//
//  OEXAnalyticsData.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 20/11/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern NSString* const OEXAnalyticsKeyBlockID;
extern NSString* const OEXAnalyticsKeyCourseID;
extern NSString* const OEXAnalyticsKeyOrientation;
extern NSString* const OEXAnalyticsKeyProvider;
extern NSString* const OEXAnalyticsKeySupported;
extern NSString* const OEXAnalyticsKeyQueryString;

// TODO rename these to be more like the above
#define key_app_name @"app_name"
#define key_app_version @"app_version"
#define key_username @"username"
#define key_email @"email"
#define key_name @"name"
#define key_old_time @"old_time"
#define key_new_time @"new_time"
#define key_seek_type @"seek_type"
#define key_requested_skip_interval @"requested_skip_interval"
#define key_module_id @"module_id"
#define key_code @"code"
#define key_current_time @"current_time"
#define key_course_id @"course_id"
#define key_open_in_browser @"open_in_browser_url"
#define key_component @"component"
#define key_context @"context"
#define key_data @"data"
#define key_unit_url @"context"
#define key_old_speed @"old_speed"
#define key_new_speed @"new_speed"
#define key_component @"component"
#define key_No_Of_Videos @"number_of_videos"
#define key_courseSection @"course_section"
#define key_courseSubsection @"course_subsection"
#define key_fullscreen @"settings.video.fullscreen"
#define key_method @"method"
#define key_target_url @"target_url"
#define key_language @"language"
#define key_rating @"rating"
#define key_play_medium @"play_medium"

// Values

#define value_app_name @"edx.mobileapp.iOS"
#define value_skip @"skip"
#define value_mobile @"mobile"
#define value_videoplayer @"videoplayer"
#define value_downloadmodule @"downloadmodule"
#define value_play_medium_youtube @"youtube"

// Event Names

extern NSString* const OEXAnalyticsEventAnnouncementNotificationReceived;
extern NSString* const OEXAnalyticsEventAnnouncementNotificationTapped;
extern NSString* const OEXAnalyticsEventComponentViewed;
extern NSString* const OEXAnalyticsEventPictureSet;
extern NSString* const OEXAnalyticsEventProfileViewed;
extern NSString* const OEXAnalyticsEventScreen;
extern NSString* const OEXAnalyticsEventCertificateShared;
extern NSString* const OEXAnalyticsEventCourseShared;

// TODO rename these to be more like the above
#define value_video_loaded @"edx.video.loaded"
#define value_video_speed @"edx.bi.video.speed.changed"
#define value_video_played @"edx.video.played"
#define value_video_paused @"edx.video.paused"
#define value_video_stopped @"edx.video.stopped"
//The seek event name has been changed as per MOB-1274
#define value_video_seeked @"edx.video.position.changed"
#define value_transcript_shown @"edx.video.transcript.shown"
#define value_transcript_hidden @"edx.video.transcript.hidden"

#define value_video_downloaded @"edx.bi.video.downloaded"
#define value_bulk_download_section @"edx.bi.video.section.bulkdownload.requested"
#define value_bulk_download_subsection @"edx.bi.video.subsection.bulkdownload.requested"
#define value_single_download @"edx.bi.video.download.requested"
#define value_fullscreen @"edx.bi.video.screen.fullscreen.toggled"
#define value_logout @"edx.bi.app.user.logout"
#define value_browser_launched @"edx.bi.app.browser.launched"
#define value_transcript_language @"edx.bi.video.transcript.language.selected"
#define value_no_acccout @"edx.bi.app.user.no_account"
#define value_find_courses @"edx.bi.app.search.find_courses.clicked"

// Categories

extern NSString* const OEXAnalyticsCategoryNavigation;
extern NSString* const OEXAnalyticsCategoryNotifications;
extern NSString* const OEXAnalyticsCategoryProfile;
extern NSString* const OEXAnalyticsCategoryScreen;
extern NSString* const OEXAnalyticsCategoryUserEngagement;

// Values
extern NSString* const OEXAnalyticsValueNavigationModeVideo;
extern NSString* const OEXAnalyticsValueNavigationModeFull;
extern NSString* const OEXAnalyticsValueNavigationModeVideo;
extern NSString* const OEXAnalyticsValueOrientationLandscape;
extern NSString* const OEXAnalyticsValueOrientationPortrait;
extern NSString* const OEXAnalyticsValuePhotoSourceCamera;
extern NSString* const OEXAnalyticsValuePhotoSourceLibrary;

// Screens
extern NSString* const OEXAnalyticsScreenLaunch;
extern NSString* const OEXAnalyticsScreenRegister;
extern NSString* const OEXAnalyticsScreenCourseDashboard;
extern NSString* const OEXAnalyticsScreenMyCourses;
extern NSString* const OEXAnalyticsScreenCourseOutline;
extern NSString* const OEXAnalyticsScreenSectionOutline;
extern NSString* const OEXAnalyticsScreenUnitDetail;
extern NSString* const OEXAnalyticsScreenHandouts;
extern NSString* const OEXAnalyticsScreenAnnouncements;
extern NSString* const OEXAnalyticsScreenFindCourses;
extern NSString* const OEXAnalyticsScreenCourseInfo;
extern NSString* const OEXAnalyticsScreenProfileView;
extern NSString* const OEXAnalyticsScreenProfileEdit;
extern NSString* const OEXAnalyticsScreenCropPhoto;
extern NSString* const OEXAnalyticsScreenChooseFormValue;
extern NSString* const OEXAnalyticsScreenEditTextFormValue;
extern NSString* const OEXAnalyticsScreenCertificate;
extern NSString* const OEXAnalyticsScreenViewTopics;
extern NSString* const OEXAnalyticsScreenSearchThreads;
extern NSString* const OEXAnalyticsScreenDownloads;
extern NSString* const OEXAnalyticsScreenSettings;

NS_ASSUME_NONNULL_END
