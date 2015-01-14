//
//  Analytics.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 24/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "Analytics.h"
#import "AnalyticsData.h"
#import "NSMutableDictionary+EDXSafeAccess.h"


@interface EDXAnalyticsEvent : NSObject

@property (copy, nonatomic) NSString* openInBrowserURL;
@property (copy, nonatomic) NSString* courseID;
@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSString* displayName;

@end

@implementation EDXAnalyticsEvent
@end

@interface EDXAnalyticsVideoEvent : EDXAnalyticsEvent

@property (copy, nonatomic) NSString* moduleID;

@end

@implementation EDXAnalyticsVideoEvent
@end



@implementation Analytics


#pragma mark - GA events

+ (void)trackEvent:(EDXAnalyticsEvent*)event forComponent:(NSString*)component withInfo:(NSDictionary*)info {
    
    NSMutableDictionary* context = @{}.mutableCopy;
    [context safeSetObject:value_app_name forKey:key_app_name];
    
    // These are optional depending on the event
    [context setObjectOrNil:component forKey:key_component];
    [context setObjectOrNil:event.courseID forKey:key_course_id];
    [context setObjectOrNil:event.openInBrowserURL forKey:key_open_in_browser];
    
    NSMutableDictionary* data = [[NSMutableDictionary alloc] initWithDictionary:info];
    
    NSDictionary* properties = @{
                                 key_data : data,
                                 key_context : context,
                                 key_name : event.name
                                 };
    
    [[SEGAnalytics sharedAnalytics] track:event.displayName properties:properties];
}

+ (void)trackVideoEvent:(EDXAnalyticsVideoEvent*)event forComponent:(NSString*)component withInfo:(NSDictionary*)info {
    NSMutableDictionary* fullInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
    [fullInfo setObjectOrNil:event.moduleID forKey:key_module_id];
    [fullInfo setObjectOrNil:value_mobile forKey:key_code];
    [self trackEvent:event forComponent:component withInfo:fullInfo];
}

+ (void)trackVideoPlayerEvent:(EDXAnalyticsVideoEvent*)event withInfo:(NSDictionary*)info {
    [self trackVideoEvent:event forComponent:value_videoplayer withInfo:info];
}

+ (void)trackVideoDownloadEvent:(EDXAnalyticsVideoEvent*)event withInfo:(NSDictionary*)info {
    [self trackVideoEvent:event forComponent:value_downloadmodule withInfo:info];
}

+(void)identifyUser:(NSString*)userID
              Email:(NSString *)email
           Username:(NSString *)username
{
    if (email && username)
        [[SEGAnalytics sharedAnalytics] identify:userID traits:@{
                                                                 key_email:email,
                                                                 key_username:username
                                                                 }];
    
}

+(void)trackVideoLoading:(NSString *)videoId
                CourseID:(NSString *)courseId
                 UnitURL:(NSString *)unitUrl
{

    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Loaded Video";
    event.name = value_video_loaded;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;
    
    [self trackVideoPlayerEvent:event withInfo:@{}];
}



+(void)trackVideoPlaying:(NSString *)videoId
             CurrentTime:(NSTimeInterval)currentTime
                CourseID:(NSString *)courseId
                 UnitURL:(NSString *)unitUrl
{
//    Disabled until we can fix the semantics of when this fires
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
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


+(void)trackVideoPause:(NSString *)videoId
           CurrentTime:(NSTimeInterval)currentTime
              CourseID:(NSString *)courseId
               UnitURL:(NSString *)unitUrl
{
//    Disabled until we can fix the semantics of when this fires
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
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

+(void)trackVideoStop:(NSString *)videoId
          CurrentTime:(NSTimeInterval)currentTime
             CourseID:(NSString *)courseId
              UnitURL:(NSString *)unitUrl
{
//    Disabled until we can fix the semantics of when this fires
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
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

+(void)trackShowTranscript:(NSString *)videoId
               CurrentTime:(NSTimeInterval)currentTime
                  CourseID:(NSString *)courseId
                   UnitURL:(NSString *)unitUrl
{
    

    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
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



+(void)trackHideTranscript:(NSString *)videoId
               CurrentTime:(NSTimeInterval)currentTime
                  CourseID:(NSString *)courseId
                   UnitURL:(NSString *)unitUrl
{
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
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



+ (void)trackTranscriptLanguage:(NSString *)videoID CurrentTime:(NSTimeInterval)currentTime Language:(NSString *)language CourseID:(NSString *)courseid UnitURL:(NSString *)unitURL
{
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:language forKey:key_language];
    [info safeSetObject:@(currentTime) forKey:key_current_time];
    
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Language Clicked";
    event.name = value_transcript_language;
    event.courseID = courseid;
    event.openInBrowserURL = unitURL;
    event.moduleID = videoID;
    
    [self trackVideoPlayerEvent:event withInfo:info];
}




+(void)trackVideoSeekRewind:(NSString *)videoId
          RequestedDuration:(NSTimeInterval)requestedDuration
                    OldTime:(NSTimeInterval)oldTime
                    NewTime:(NSTimeInterval)newTime
                   CourseID:(NSString *)courseId
                    UnitURL:(NSString *)unitUrl
                    SkipType:(NSString *)skip_value

{
//    Disabled until we can fix the semantics of when this fires
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
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


+(void)trackVideoSpeed:(NSString *)videoId
           CurrentTime:(double)currentTime
              CourseID:(NSString *)courseId
               UnitURL:(NSString *)unitUrl
               OldSpeed:(NSString *)oldSpeed
               NewSpeed:(NSString *)newSpeed
{
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:oldSpeed forKey:key_old_speed];
    [info safeSetObject:newSpeed forKey:key_new_speed];
    [info safeSetObject:@(currentTime) forKey:key_current_time];
    
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
    event.displayName = @"Speed Change Video";
    event.name = value_video_speed;
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;

    [self trackVideoPlayerEvent:event withInfo:info];
    
}

+(void)trackDownloadComplete:(NSString *)videoId
                    CourseID:(NSString *)courseId
                     UnitURL:(NSString *)unitUrl
{
    NSMutableDictionary* info = @{}.mutableCopy;

    
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
    event.name = value_video_downloaded;
    event.displayName = @"Video Downloaded";
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoId;
    
    [self trackVideoDownloadEvent:event withInfo:info];
}


+(void)trackSectionBulkVideoDownload:(NSString *)section
                            CourseID:(NSString *)courseId
                          VideoCount:(long)count
{
    [self trackSubSectionBulkVideoDownload:section Subsection:nil CourseID:courseId VideoCount:count];
}


+(void)trackSubSectionBulkVideoDownload:(NSString *)section
                             Subsection:(NSString *)subsection
                            CourseID:(NSString *)courseId
                          VideoCount:(long)count
{
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:section forKey:key_courseSection];
    [info safeSetObject:@(count) forKey:key_No_Of_Videos];

    // can be nil
    [info setObjectOrNil:subsection forKey:key_courseSubsection];
    
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
    
    if (subsection)
    {
        event.name = value_bulk_download_subsection;
        event.displayName = @"Bulk Download Subsection";
    }
    else
    {
        event.name = value_bulk_download_section;
        event.displayName = @"Bulk Download Section";
    }
    
    event.courseID = courseId;
    
    [self trackVideoDownloadEvent:event withInfo:info];
}


+(void)trackSingleVideoDownload:(NSString *)videoID
                               CourseID:(NSString *)courseId
                                UnitURL:(NSString *)unitUrl
{
    NSMutableDictionary* info = @{}.mutableCopy;
    
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
    event.name = value_single_download;
    event.displayName = @"Single Video Download";
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoID;
    
    [self trackVideoDownloadEvent:event withInfo:info];
}


+(void)trackVideoOrientation:(NSString *)videoID
                    CourseID:(NSString *)courseId
                 CurrentTime:(CGFloat)currentTime
                        Mode:(BOOL)isFullscreen
                     UnitURL:(NSString *)unitUrl
{
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:@(isFullscreen) forKey:key_fullscreen];
    [info safeSetObject:@(currentTime) forKey:key_current_time];
    
    EDXAnalyticsVideoEvent* event = [[EDXAnalyticsVideoEvent alloc] init];
    event.name = value_single_download;
    event.displayName = @"Screen Toggled";
    event.courseID = courseId;
    event.openInBrowserURL = unitUrl;
    event.moduleID = videoID;
    
    [self trackVideoPlayerEvent:event withInfo:info];
}


+(void)trackUserLogin:(NSString *)method
{
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:method forKey:key_method];
    
    EDXAnalyticsEvent* event = [[EDXAnalyticsEvent alloc] init];
    event.name = value_login;
    event.displayName = @"User Login";
    [self trackEvent:event forComponent:nil withInfo:info];
}

+(void)trackUserLogout
{
    EDXAnalyticsEvent* event = [[EDXAnalyticsEvent alloc] init];
    event.name = value_logout;
    event.displayName = @"User Logout";
    [self trackEvent:event forComponent:nil withInfo:@{}];
}



#pragma mark - Screens

+ (void)screenViewsTracking:(NSString *)screenName
{
    if(screenName)
        [[SEGAnalytics sharedAnalytics] screen:screenName properties:@{
                                                                       key_context : @{
                                                                               key_appname : value_appname
                                                                               }
                                                                       }];
    
}


#pragma mark - View on web

+ (void)trackOpenInBrowser:(NSString *)URL
{
    NSMutableDictionary* info = @{}.mutableCopy;
    [info safeSetObject:URL forKey:key_target_url];
    
    EDXAnalyticsEvent* event = [[EDXAnalyticsEvent alloc] init];
    event.name = value_browser_launched;
    event.displayName = @"Browser Launched";
    [self trackEvent:event forComponent:nil withInfo:info];
}

+ (void)trackUserDoesNotHaveAccount
{
    EDXAnalyticsEvent* event = [[EDXAnalyticsEvent alloc] init];
    event.name = value_no_acccout;
    event.displayName = @"User Has No Account Clicked";
    [self trackEvent:event forComponent:nil withInfo:@{}];
}

+ (void)trackUserFindsCourses
{
    EDXAnalyticsEvent* event = [[EDXAnalyticsEvent alloc] init];
    event.name = value_find_courses;
    event.displayName = @"Find Courses Clicked";
    [self trackEvent:event forComponent:nil withInfo:@{}];
}


+ (void)resetIdentifyUser
{
    [[SEGAnalytics sharedAnalytics] reset];
}


@end
