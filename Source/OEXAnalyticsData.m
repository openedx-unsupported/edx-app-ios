//
//  OEXAnalyticsData.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/16/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXAnalyticsData.h"

NSString* const OEXAnalyticsKeyBlockID = @"block-id";
NSString* const OEXAnalyticsKeyCourseID = @"course-id";
NSString* const OEXAnalyticsKeyNavigationMode = @"navigation-mode";
NSString* const OEXAnalyticsKeyOrientation = @"device-orientation";
NSString* const OEXAnalyticsKeyProvider = @"provider";
NSString* const OEXAnalyticsKeySupported = @"supported";

NSString* const OEXAnalyticsEventAnnouncementNotificationReceived = @"edx.bi.app.notification.course.update.received";
NSString* const OEXAnalyticsEventAnnouncementNotificationTapped = @"edx.bi.app.notification.course.update.tapped";
NSString* const OEXAnalyticsEventCourseEnrollment = @"edx.bi.app.course.enroll.clicked";
NSString* const OEXAnalyticsEventRegistration = @"edx.bi.app.user.register.clicked";
NSString* const OEXAnalyticsEventOpenInBrowser = @"edx.bi.app.navigation.open-in-browser";
NSString* const OEXAnalyticsEventComponentViewed = @"edx.bi.app.navigation.component.viewed";
NSString* const OEXAnalyticsEventOutlineModeChanged = @"edx.bi.app.navigation.switched-mode.clicked";

NSString* const OEXAnalyticsCategoryUserEngagement = @"user-engagement";
NSString* const OEXAnalyticsCategoryConversion = @"conversion";
NSString* const OEXAnalyticsCategoryNavigation = @"navigation";
NSString* const OEXAnalyticsCategoryNotifications = @"notifications";

NSString* const OEXAnalyticsValueNavigationModeFull = @"full";
NSString* const OEXAnalyticsValueNavigationModeVideo = @"video";
NSString* const OEXAnalyticsValueOrientationLandscape = @"landscape";
NSString* const OEXAnalyticsValueOrientationPortrait = @"portrait";
