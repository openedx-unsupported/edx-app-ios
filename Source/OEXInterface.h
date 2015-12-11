//
//  EdXInterface.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "OEXNetworkInterface.h"
#import "OEXCourse.h"
#import "OEXStorageInterface.h"

@class OEXHelperVideoDownload;
@class OEXUserDetails;
@class UserCourseEnrollment;

/// Fires when the course list changes
extern NSString* const OEXCourseListChangedNotification;
/// NSNotification userInfo key for OEXCourseListChangedNotification. An NSArray of OEXCourse*
extern NSString* const OEXCourseListKey;

extern NSString* const OEXVideoStateChangedNotification;
extern NSString* const OEXDownloadProgressChangedNotification;
extern NSString* const OEXDownloadEndedNotification;


// This class requires significant refactoring
// Think very hard before adding anything to it
@interface OEXInterface : NSObject <OEXNetworkInterfaceDelegate, UIAlertViewDelegate>

+ (instancetype)sharedInterface;

//Common Data

// These two indices are used to check the selected index of CC and Video Speed
// Works for both portrait and landscape mode
@property (nonatomic, assign) NSInteger selectedCCIndex;
@property (nonatomic, assign) NSInteger selectedVideoSpeedIndex;

@property (nonatomic, strong) NSArray<UserCourseEnrollment*>* courses;
- (OEXCourse*)courseWithID:(NSString*)courseID;

@property (nonatomic, weak) id <OEXStorageInterface>  storage;

// [String(Course.video_outline) : OEXHelperVideoDownload]
// TODO: Make this indexed by courseID instead of course.video_outline
@property (nonatomic, strong) NSMutableDictionary* courseVideos;

//Reachability
@property (nonatomic, assign) BOOL reachable;

//Total progress
@property (nonatomic, assign) float totalProgress;
@property (nonatomic, strong) NSMutableSet<UIView*>* progressViews;
@property (nonatomic, assign) int numberOfRecentDownloads;

#pragma Common Methods
+ (BOOL)isURLForVideo:(NSString*)URLString;
+ (BOOL)isURLForImage:(NSString*)URLString;
+ (BOOL)isURLForedXDomain:(NSString*)URLString;

#pragma mark Resource downloading
- (BOOL)downloadWithRequestString:(NSString*)URLString forceUpdate:(BOOL)update;
- (NSData*)resourceDataForURLString:(NSString*)URLString downloadIfNotAvailable:(BOOL)shouldDownload;
- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler;      // This method get called while user logged out from app
// videos : OEXHelperVideoDownload

#pragma CC methods
+ (void)setCCSelectedLanguage:(NSString*)language;
+ (NSString*)getCCSelectedLanguage;

+ (void)setCCSelectedPlaybackSpeed:(OEXVideoSpeed) speed;
+ (OEXVideoSpeed)getCCSelectedPlaybackSpeed;
+ (float) getOEXVideoSpeed:(OEXVideoSpeed) speed;

#pragma mark Last Accessed
- (OEXHelperVideoDownload*)lastAccessedSubsectionForCourseID:(NSString*)courseID;

#pragma mark Video Management
/// videos is an array of OEXVideoSummary
- (void)addVideos:(NSArray*)videos forCourseWithID:(NSString*)courseID;
/// videos is an array of OEXHelperVideoDownload
/// This should really take a courseID not the outline URL, but that will require more serious refactoring
- (void)setVideos:(NSArray*)videos forURL:(NSString*)URLString;
- (NSString*)URLStringForType:(NSString*)type;
- (NSMutableArray*)videosForChapterID:(NSString*)chapter
                            sectionID:(NSString*)section
                                  URL:(NSString*)URLString;

- (NSArray*)coursesAndVideosForDownloadState:(OEXDownloadState)state;
- (NSArray<OEXHelperVideoDownload*>*)allVideosForState:(OEXDownloadState)state;

#pragma mark Wifi Only
+ (BOOL)shouldDownloadOnlyOnWifi;
+ (void)setDownloadOnlyOnWifiPref:(BOOL)should;
@property (readonly, nonatomic) BOOL shouldDownloadOnlyOnWifi;
//+ (void)clearSession;

#pragma mark - Bulk Download
- (float)showBulkProgressViewForCourse:(OEXCourse*)course chapterID:(NSString*)chapterID sectionID:(NSString*)sectionID;
/*
 New methods for refactoring
 */
// Download  video
- (void)startDownloadForVideo:(OEXHelperVideoDownload*)video completionHandler:(void (^)(BOOL sucess))completionHandler;
// Cancel Video download
- (void)cancelDownloadForVideo:(OEXHelperVideoDownload*)video completionHandler:(void (^)(BOOL))completionHandler;

// Start All paused downloads
- (void)startAllBackgroundDownloads;

/// @param array An array of OEXHelperVideoDownload representing the videos to download
- (NSInteger)downloadVideos:(NSArray<OEXHelperVideoDownload*>*)videos;

/// @param array An array of video ids representing the videos to download
- (NSInteger)downloadVideosWithIDs:(NSArray<NSString*>*)videoIDs courseID:(NSString*)courseID;

- (NSArray<OEXHelperVideoDownload*>*)statesForVideosWithIDs:(NSArray<NSString*>*)videoIDs courseID:(NSString*)courseID;

- (void)deleteDownloadedVideoForVideoId:(NSString*)videoId completionHandler:(void (^)(BOOL success))completionHandler;

- (VideoData*)insertVideoData:(OEXHelperVideoDownload*)helperVideo;

#pragma mark- For Refresh of all Courses.
- (void)setAllEntriesUnregister;
/// @param courses Array of OEXCourse*
- (void)setRegisteredCourses:(NSArray*)courses;
- (void)deleteUnregisteredItems;

#pragma mark Video Management
- (OEXHelperVideoDownload*)stateForVideoWithID:(NSString*)videoID courseID:(NSString*)courseID;
- (OEXDownloadState)downloadStateForVideoWithID:(NSString*)videoID;
- (OEXPlayedState)watchedStateForVideoWithID:(NSString*)videoID;
- (float)lastPlayedIntervalForVideo:(OEXHelperVideoDownload*)video;
- (void)markVideoState:(OEXPlayedState)state forVideo:(OEXHelperVideoDownload*)video;
- (void)markLastPlayedInterval:(float)playedInterval forVideo:(OEXHelperVideoDownload*)video;
- (NSArray*)videosOfCourseWithURLString:(NSString*)URL;
- (NSString*)openInBrowserLinkForCourse:(OEXCourse*)course;

- (NSDictionary*)processVideoSummaryList:(NSData*)data URLString:(NSString*)URLString;

/// @return Array of OEXVideoPathEntry
- (NSArray*)chaptersForURLString:(NSString*)URL;

/// @return Array of OEXVideoPathEntry
- (NSArray*)sectionsForChapterID:(NSString*)chapterID URLString:(NSString*)URL;

#pragma mark - Closed Captioning
- (void)downloadAllTranscriptsForVideo:(OEXHelperVideoDownload*)obj;

#pragma mark - Update Last Accessed from server
- (void)updateLastVisitedModule:(NSString*)module forCourseID:(NSString*)courseID;
- (void)getLastVisitedModuleForCourseID:(NSString*)courseID;
- (void)activateInterfaceForUser:(OEXUserDetails*)user;

#pragma mark - Analytics Call
- (void)sendAnalyticsEvents:(OEXVideoState)state withCurrentTime:(NSTimeInterval)currentTime forVideo:(OEXHelperVideoDownload*)video;

#pragma mark - Course Enrollements
/** Finds the user's enrollement for a course */
- (UserCourseEnrollment*) enrollmentForCourse:(OEXCourse*)course;

@end

@protocol OEXInterfaceProvider <NSObject>

@property (readonly, nonatomic, strong) OEXInterface* interface;

@end
