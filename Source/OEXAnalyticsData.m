//
//  OEXAnalyticsData.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/16/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXAnalyticsData.h"

NSString* const OEXAnalyticsKeyBlockID = @"block-id";
NSString* const OEXAnalyticsKeyCourseID = @"course-id";
NSString* const OEXAnalyticsKeyOrientation = @"device-orientation";
NSString* const OEXAnalyticsKeyProvider = @"provider";
NSString* const OEXAnalyticsKeySupported = @"supported";
NSString* const OEXAnalyticsKeyQueryString = @"query_string";

NSString* const OEXAnalyticsEventAnnouncementNotificationReceived = @"edx.bi.app.notification.course.update.received";
NSString* const OEXAnalyticsEventAnnouncementNotificationTapped = @"edx.bi.app.notification.course.update.tapped";
NSString* const OEXAnalyticsEventPictureSet = @"edx.bi.app.profile.setphoto";
NSString* const OEXAnalyticsEventProfileViewed = @"edx.bi.app.profile.view";

NSString* const OEXAnalyticsEventComponentViewed = @"edx.bi.app.navigation.component.viewed";
NSString* const OEXAnalyticsEventScreen = @"edx.bi.app.navigation.screen";
NSString* const OEXAnalyticsEventCertificateShared = @"edx.bi.app.certificate.shared";
NSString* const OEXAnalyticsEventCourseShared = @"edx.bi.app.course.shared";

NSString* const OEXAnalyticsCategoryNavigation = @"navigation";
NSString* const OEXAnalyticsCategoryNotifications = @"notifications";
NSString* const OEXAnalyticsCategoryProfile = @"profiles";
NSString* const OEXAnalyticsCategoryScreen = @"screen";
NSString* const OEXAnalyticsCategoryUserEngagement = @"user-engagement";

NSString* const OEXAnalyticsValueNavigationModeFull = @"full";
NSString* const OEXAnalyticsValueNavigationModeVideo = @"video";
NSString* const OEXAnalyticsValueOrientationLandscape = @"landscape";
NSString* const OEXAnalyticsValueOrientationPortrait = @"portrait";
NSString* const OEXAnalyticsValuePhotoSourceCamera = @"camera";
NSString* const OEXAnalyticsValuePhotoSourceLibrary = @"library";

NSString* const OEXAnalyticsScreenLaunch = @"Launch";
NSString* const OEXAnalyticsScreenRegister = @"Register";
NSString* const OEXAnalyticsScreenCourseDashboard = @"Course Dashboard";
NSString* const OEXAnalyticsScreenMyCourses = @"My Courses";
NSString* const OEXAnalyticsScreenCourseOutline = @"Course Outline";
NSString* const OEXAnalyticsScreenSectionOutline = @"Section Outline";
NSString* const OEXAnalyticsScreenUnitDetail = @"Unit Detail";
NSString* const OEXAnalyticsScreenHandouts = @"Course Handouts";
NSString* const OEXAnalyticsScreenAnnouncements = @"Course Announcements";
NSString* const OEXAnalyticsScreenFindCourses = @"Find Courses";
NSString* const OEXAnalyticsScreenCourseInfo = @"Course Info";
NSString* const OEXAnalyticsScreenProfileView = @"Profile View";
NSString* const OEXAnalyticsScreenProfileEdit = @"Profile Edit";
NSString* const OEXAnalyticsScreenCropPhoto = @"Crop Photo";
NSString* const OEXAnalyticsScreenChooseFormValue = @"Choose Form Value";
NSString* const OEXAnalyticsScreenEditTextFormValue = @"Edit Text Form Value";
NSString* const OEXAnalyticsScreenCertificate = @"View Certificate";
NSString* const OEXAnalyticsScreenViewTopics = @"Forum: View Topics";
NSString* const OEXAnalyticsScreenSearchThreads = @"Forum: Search Threads";
NSString* const OEXAnalyticsScreenDownloads = @"Downloads";
NSString* const OEXAnalyticsScreenSettings = @"Settings";
