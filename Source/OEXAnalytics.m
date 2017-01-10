//
//  Analytics.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 24/11/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

@import edXCore;

#import "OEXAnalytics.h"

#import "OEXAnalyticsData.h"
#import "OEXAnalyticsTracker.h"
#import "NSMutableDictionary+OEXSafeAccess.h"
#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXSession.h"
#import "edx-Swift.h"

@implementation OEXAnalyticsEvent

- (id)copyWithZone:(NSZone *)zone {
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent allocWithZone:zone] init];
    event.openInBrowserURL = self.openInBrowserURL;
    event.courseID = self.courseID;
    event.name = self.name;
    event.displayName = self.displayName;
    event.category = self.category;
    event.label = self.label;
    return self;
}

- (NSString*)description {
    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
    [info setObjectOrNil:self.label forKey:@"label"];
    [info setObjectOrNil:self.displayName forKey:@"displayName"];
    [info setObjectOrNil:self.category forKey:@"category"];
    [info setObjectOrNil:self.name forKey:@"name"];
    [info setObjectOrNil:self.courseID forKey:@"courseID"];
    [info setObjectOrNil:self.openInBrowserURL forKey:@"openInBrowserURL"];
    return [NSString stringWithFormat:@"<%@: %p %@>", self.class, self, info];
}
@end

@interface OEXAnalyticsVideoEvent : OEXAnalyticsEvent

@property (copy, nonatomic) NSString* moduleID;

@end

@implementation OEXAnalyticsVideoEvent
@end

@interface OEXAnalytics ()

@property (strong, nonatomic) NSMutableArray* trackers;

@end

static OEXAnalytics* sAnalytics;

@implementation OEXAnalytics

+ (void)setSharedAnalytics:(OEXAnalytics*)analytics {
    sAnalytics = analytics;
}

+ (instancetype)sharedAnalytics {
    return sAnalytics;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        self.trackers = [[NSMutableArray alloc] init];
        [self addObservers];
    }
    return self;
}

- (void)addTracker:(id <OEXAnalyticsTracker>)tracker {
    [self.trackers addObject:tracker];
}

- (void)trackEvent:(OEXAnalyticsEvent*)event forComponent:(NSString*)component withInfo:(NSDictionary*)info {
    for(id <OEXAnalyticsTracker> tracker in self.trackers) {
        [tracker trackEvent:event forComponent:component withProperties:info];
    }
}

- (void) addObservers {
    [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionEndedNotification action:^(NSNotification *notification, OEXAnalytics* observer, id<OEXRemovable> removable) {
        [observer trackUserLogout];
        [observer clearIdentifiedUser];
    }];
}

#pragma mark - Screens

- (void)trackScreenWithName:(NSString*)screenName courseID:(nullable NSString*)courseID value:(nullable NSString*)value {

    [self trackScreenWithName:screenName courseID:courseID value:value additionalInfo:@{}];
}

- (void) trackScreenWithName:(NSString *)screenName courseID:(nullable NSString *)courseID value:(nullable NSString*)value additionalInfo:(NSDictionary<NSString*, NSString*>*) info {
    if(screenName) {
        for(id <OEXAnalyticsTracker> tracker in self.trackers) {
            [tracker trackScreenWithName:screenName courseID:courseID value:value additionalInfo:info];
        }
    }
}

- (void)trackScreenWithName:(NSString *)screenName {
    [self trackScreenWithName:screenName courseID:nil value:nil additionalInfo:@{}];
}

#pragma mark - User Identification

- (void)identifyUser:(OEXUserDetails*)user {
    for(id <OEXAnalyticsTracker> tracker in self.trackers) {
        [tracker identifyUser:user];
    }
}

- (void)clearIdentifiedUser {
    for(id <OEXAnalyticsTracker> tracker in self.trackers) {
        [tracker clearIdentifiedUser];
    }
}

#pragma mark Video Events

- (void)trackVideoEvent:(OEXAnalyticsVideoEvent*)event forComponent:(NSString*)component withInfo:(NSDictionary*)info {
    NSMutableDictionary* fullInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
    [fullInfo setObjectOrNil:event.moduleID forKey:key_module_id];
    [fullInfo setObjectOrNil:value_mobile forKey:key_code];
    [self trackEvent:event forComponent:component withInfo:fullInfo];
}

- (void)trackVideoPlayerEvent:(OEXAnalyticsVideoEvent*)event withInfo:(NSDictionary*)info {
    [self trackVideoEvent:event forComponent:value_videoplayer withInfo:info];
}

- (void)trackVideoDownloadEvent:(OEXAnalyticsVideoEvent*)event withInfo:(NSDictionary*)info {
    [self trackVideoEvent:event forComponent:value_downloadmodule withInfo:info];
}

- (void)trackVideoLoading:(NSString*)videoId
                 CourseID:(NSString*)courseId
                  UnitURL:(NSString*)unitUrl {
    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Loaded Video";
    event.name = value_video_loaded;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event withInfo:@{}];
}

- (void)trackVideoPlaying:(NSString*)videoId
              CurrentTime:(NSTimeInterval)currentTime
                 CourseID:(NSString*)courseId
                  UnitURL:(NSString*)unitUrl {

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Played Video";
    event.name = value_video_played;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event
                       withInfo:@{
         key_current_time : @(currentTime)
     }];
}

- (void)trackVideoPause:(NSString*)videoId
            CurrentTime:(NSTimeInterval)currentTime
               CourseID:(NSString*)courseId
                UnitURL:(NSString*)unitUrl {

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Paused Video";
    event.name = value_video_paused;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event
                       withInfo:@{
         key_current_time : @(currentTime)
     }];
}

- (void)trackVideoStop:(NSString*)videoId
           CurrentTime:(NSTimeInterval)currentTime
              CourseID:(NSString*)courseId
               UnitURL:(NSString*)unitUrl {

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Stopped Video";
    event.name = value_video_stopped;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event
                       withInfo:@{
         key_current_time : @(currentTime)
     }];
}

- (void)trackShowTranscript:(NSString*)videoId
                CurrentTime:(NSTimeInterval)currentTime
                   CourseID:(NSString*)courseId
                    UnitURL:(NSString*)unitUrl {
    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Show Transcript";
    event.name = value_transcript_shown;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event
                       withInfo:@{
         key_current_time : @(currentTime)
     }];
}

- (void)trackHideTranscript:(NSString*)videoId
                CurrentTime:(NSTimeInterval)currentTime
                   CourseID:(NSString*)courseId
                    UnitURL:(NSString*)unitUrl {
    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Hide Transcript";
    event.name = value_transcript_hidden;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event
                       withInfo:@{
         key_current_time : @(currentTime)
     }];
}

- (void)trackTranscriptLanguage:(NSString*)videoID CurrentTime:(NSTimeInterval)currentTime Language:(NSString*)language CourseID:(NSString*)courseid UnitURL:(NSString*)unitURL {
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:language forKey:key_language];
    [info safeSetObject:@(currentTime) forKey:key_current_time];

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Language Clicked";
    event.name = value_transcript_language;
    event.courseID = courseid;
    event.openInBrowserURL = unitURL;
    event.moduleID = videoID;

    [self trackVideoPlayerEvent:event withInfo:info];
}

- (void)trackVideoSeekRewind:(NSString*)videoId
           RequestedDuration:(NSTimeInterval)requestedDuration
                     OldTime:(NSTimeInterval)oldTime
                     NewTime:(NSTimeInterval)newTime
                    CourseID:(NSString*)courseId
                     UnitURL:(NSString*)unitUrl
                    SkipType:(NSString*)skip_value {

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Video Seeked";
    event.name = value_video_seeked;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event
                       withInfo:@{
         key_old_time : @(oldTime),
         key_new_time : @(newTime),
         key_requested_skip_interval : @(requestedDuration),
         key_seek_type : skip_value
     }];
}

- (void)trackVideoSpeed:(NSString*)videoId
            CurrentTime:(double)currentTime
               CourseID:(NSString*)courseId
                UnitURL:(NSString*)unitUrl
               OldSpeed:(NSString*)oldSpeed
               NewSpeed:(NSString*)newSpeed {
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:oldSpeed forKey:key_old_speed];
    [info safeSetObject:newSpeed forKey:key_new_speed];
    [info safeSetObject:@(currentTime) forKey:key_current_time];

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Speed Change Video";
    event.name = value_video_speed;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event withInfo:info];
}

- (void)trackDownloadComplete:(NSString*)videoId
                     CourseID:(NSString*)courseId
                      UnitURL:(NSString*)unitUrl {
    NSMutableDictionary* info = @{}.mutableCopy;

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.name = value_video_downloaded;
    event.displayName = @"Video Downloaded";
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoDownloadEvent:event withInfo:info];
}

- (void)trackSectionBulkVideoDownload:(NSString*)section
                             CourseID:(NSString*)courseId
                           VideoCount:(long)count {
    [self trackSubSectionBulkVideoDownload:section Subsection:nil CourseID:courseId VideoCount:count];
}

- (void)trackSubSectionBulkVideoDownload:(NSString*)section
                              Subsection:(NSString*)subsection
                                CourseID:(NSString*)courseId
                              VideoCount:(long)count {
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:section forKey:key_courseSection];
    [info safeSetObject:@(count) forKey:key_No_Of_Videos];

    // can be nil
    [info setObjectOrNil:subsection forKey:key_courseSubsection];

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];

    if(subsection) {
        event.name = value_bulk_download_subsection;
        event.displayName = @"Bulk Download Subsection";
    }
    else {
        event.name = value_bulk_download_section;
        event.displayName = @"Bulk Download Section";
    }

    event.courseID = courseId;

    [self trackVideoDownloadEvent:event withInfo:info];
}

- (void)trackSingleVideoDownload:(NSString*)videoID
                        CourseID:(NSString*)courseId
                         UnitURL:(NSString*)unitUrl {
    NSMutableDictionary* info = @{}.mutableCopy;

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.name = value_single_download;
    event.displayName = @"Single Video Download";
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoID;

    [self trackVideoDownloadEvent:event withInfo:info];
}

- (void)trackVideoOrientation:(NSString*)videoID
                     CourseID:(NSString*)courseId
                  CurrentTime:(CGFloat)currentTime
                         Mode:(BOOL)isFullscreen
                      UnitURL:(NSString*)unitUrl {
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:@(isFullscreen) forKey:key_fullscreen];
    [info safeSetObject:@(currentTime) forKey:key_current_time];

    OEXAnalyticsVideoEvent* event = [[OEXAnalyticsVideoEvent alloc] init];
    event.name = value_single_download;
    event.displayName = @"Screen Toggled";
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoID;

    [self trackVideoPlayerEvent:event withInfo:info];
}

- (void)trackUserLogin:(NSString*)method {
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:method forKey:key_method];

    OEXAnalyticsEvent* event = [OEXAnalytics loginEvent];
    [self trackEvent:event forComponent:nil withInfo:info];
}

- (void)trackUserLogout {
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = value_logout;
    event.displayName = @"User Logout";
    [self trackEvent:event forComponent:nil withInfo:@{}];
}

- (void)trackRegistrationWithProvider:(NSString *)provider {
    OEXAnalyticsEvent* event = [OEXAnalytics registerEvent];
    
    NSMutableDictionary* properties = [[NSMutableDictionary alloc] init];
    [properties setObjectOrNil:provider forKey:OEXAnalyticsKeyProvider];

    [self trackEvent:event forComponent:nil withInfo:properties];
}

#pragma mark - Course Navigation

- (void)trackViewedComponentForCourseWithID:(NSString*)courseID blockID:(NSString*)blockID minifiedBlockID: (NSString*)minifiedBlockID {
    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
    [info safeSetObject:blockID forKey:OEXAnalyticsKeyBlockID];
    [info safeSetObject:courseID forKey:OEXAnalyticsKeyCourseID];
    [info safeSetObject:minifiedBlockID forKey:FirebaseAnalyticsTracker.minifiedBlockIDKey];
    
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = OEXAnalyticsEventComponentViewed;
    event.displayName = @"Component Viewed";
    event.category = OEXAnalyticsCategoryNavigation;
    event.label = event.displayName;
    
    [self trackEvent:event forComponent:nil withInfo:info];
}

#pragma mark - View on web

- (void)trackOpenInBrowserWithURL:(NSString*)URL courseID:(NSString*)courseID blockID:(NSString*)blockID minifiedBlockID: (NSString*)minifiedBlockID supported:(BOOL)supported {
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:courseID forKey:OEXAnalyticsKeyCourseID];
    [info safeSetObject:blockID forKey:OEXAnalyticsKeyBlockID];
    [info safeSetObject:minifiedBlockID forKey:FirebaseAnalyticsTracker.minifiedBlockIDKey];
    [info safeSetObject:@(supported) forKey:OEXAnalyticsKeySupported];
    [info safeSetObject:URL forKey:key_target_url];
    
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = value_browser_launched;
    event.displayName = @"Browser Launched";
    event.category = OEXAnalyticsCategoryNavigation;
    event.label = [NSString stringWithFormat:@"Open in browser - %@", supported ? @"Supported" : @"Unsupported"];
    event.openInBrowserURL = URL;
    [self trackEvent:event forComponent:nil withInfo:info];
}

#pragma mark Notifications

// Notification events
- (void)trackAnnouncementNotificationReceivedWithCourseID:(NSString*)courseID {
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = OEXAnalyticsEventAnnouncementNotificationReceived;
    event.displayName = OEXAnalyticsEventAnnouncementNotificationReceived;
    event.category = OEXAnalyticsCategoryNotifications;
    event.label = courseID;
    [self trackEvent:event forComponent:nil withInfo:@{}];
}

- (void)trackAnnouncementNotificationTappedWithCourseID:(NSString*)courseID {
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = OEXAnalyticsEventAnnouncementNotificationTapped;
    event.displayName = OEXAnalyticsEventAnnouncementNotificationTapped;
    event.category = OEXAnalyticsCategoryNotifications;
    event.label = courseID;
    [self trackEvent:event forComponent:nil withInfo:@{}];
}

#pragma mark Users

- (void)trackUserDoesNotHaveAccount {
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = value_no_acccout;
    event.displayName = @"User Has No Account Clicked";
    [self trackEvent:event forComponent:nil withInfo:@{}];
}

- (void)trackUserFindsCourses {
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = value_find_courses;
    event.displayName = @"Find Courses Clicked";
    event.category = OEXAnalyticsCategoryUserEngagement;
    event.label = @"course-discovery";
    [self trackEvent:event forComponent:nil withInfo:@{}];
}

- (void)trackUserEnrolledInCourse:(NSString*)courseID {
    OEXAnalyticsEvent* event = [OEXAnalytics enrollEvent:courseID];
    [self trackEvent:event forComponent:nil withInfo:@{}];
}

#pragma mark Course
- (void)trackCourseShared:(NSString*)courseName url:(NSString*)aboutUrl socialTarget:(NSString*)type {
    OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
    event.name = OEXAnalyticsEventCourseShared;
    event.displayName = @"Shared a course";
    event.category = OEXAnalyticsCategorySocialSharing;
    [self trackEvent:event forComponent:nil withInfo:@{@"name": courseName, @"url" : aboutUrl, @"type": type}];
}

#pragma mark- Discussion

- (void) trackDiscussionScreenWithName:(NSString *) screenName courseId:(NSString *) courseID value:(nullable NSString *) value threadId:(nullable NSString *) threadID topicId:(nullable NSString *) topicID responseID:(nullable NSString *) responseID {

    NSMutableDictionary *additionInfo = [NSMutableDictionary dictionary];
    
    [additionInfo setObjectOrNil:threadID forKey:OEXAnalyticsKeyThreadID];
    [additionInfo setObjectOrNil:topicID forKey:OEXAnalyticsKeyTopicID];
    [additionInfo setObjectOrNil:responseID forKey:OEXAnalyticsKeyResponseID];
    
    [self trackScreenWithName:screenName courseID:courseID value:value additionalInfo:additionInfo];
}

- (void) trackDiscussionSearchScreenWithName:(NSString *) screenName courseId:(NSString *) courseID value:(nullable NSString *) value searchQuery:(NSString *) query {
    [self trackScreenWithName:screenName courseID:courseID value:value additionalInfo:@{OEXAnalyticsKeyQueryString:query}];
}
@end
