//
//  OEXAnalytics.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 24/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OEXAnalyticsTracker;

@class OEXUserDetails;

@interface OEXAnalyticsEvent : NSObject

@property (copy, nonatomic) NSString* openInBrowserURL;
@property (copy, nonatomic) NSString* courseID;
@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSString* displayName;

@end

@interface OEXAnalytics : NSObject

/// Note that these are not thread safe. The expectation is that these operations only
/// immediately when the app launches or synchronously at the start of a test.
+ (void)setSharedAnalytics:(OEXAnalytics*)analytics;
+ (instancetype)sharedAnalytics;
- (void)addTracker:(id <OEXAnalyticsTracker>)tracker;

- (void)identifyUser:(OEXUserDetails*)user;

- (void)trackVideoLoading:(NSString*)videoId
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackVideoPlaying:(NSString*)videoId
    CurrentTime:(NSTimeInterval)currentTime
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackVideoPause:(NSString*)videoId
    CurrentTime:(NSTimeInterval)currentTime
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackVideoStop:(NSString*)videoId
    CurrentTime:(NSTimeInterval)currentTime
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackShowTranscript:(NSString*)videoId
    CurrentTime:(NSTimeInterval)currentTime
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackHideTranscript:(NSString*)videoId
    CurrentTime:(NSTimeInterval)currentTime
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackVideoSeekRewind:(NSString*)videoId
    RequestedDuration:(NSTimeInterval)requestedDuration
    OldTime:(NSTimeInterval)oldTime
    NewTime:(NSTimeInterval)newTime
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl
    SkipType:(NSString*)skip_value;

- (void)trackVideoSpeed:(NSString*)videoId
    CurrentTime:(double)currentTime
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl
    OldSpeed:(NSString*)oldSpeed
    NewSpeed:(NSString*)newSpeed;

- (void)trackTranscriptLanguage:(NSString*)videoID CurrentTime:(NSTimeInterval)currentTime Language:(NSString*)language CourseID:(NSString*)courseid UnitURL:(NSString*)unitURL;

- (void)trackDownloadComplete:(NSString*)videoId
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackSectionBulkVideoDownload:(NSString*)section
    CourseID:(NSString*)courseId
    VideoCount:(long)count;

- (void)trackSubSectionBulkVideoDownload:(NSString*)section
    Subsection:(NSString*)subsection
    CourseID:(NSString*)courseId
    VideoCount:(long)count;

- (void)trackSingleVideoDownload:(NSString*)videoID
    CourseID:(NSString*)courseId
    UnitURL:(NSString*)unitUrl;

- (void)trackVideoOrientation:(NSString*)videoID
    CourseID:(NSString*)courseid
    CurrentTime:(CGFloat)currentTime
    Mode:(BOOL)isFullscreen
    UnitURL:(NSString*)unitUrl;

- (void)trackUserLogin:(NSString*)method;

- (void)trackUserLogout;

- (void)trackScreenWithName:(NSString*)screenName;

- (void)trackOpenInBrowser:(NSString*)URL;

- (void)trackUserDoesNotHaveAccount;

- (void)trackUserFindsCourses;

- (void)clearIdentifiedUser;

@end
