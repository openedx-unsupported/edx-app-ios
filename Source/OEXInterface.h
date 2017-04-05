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

NS_ASSUME_NONNULL_BEGIN

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

@property (nonatomic, strong, nullable) NSArray<UserCourseEnrollment*>* courses;

@property (nonatomic, weak, nullable) id <OEXStorageInterface>  storage;

// [String(Course.video_outline) : OEXHelperVideoDownload]
// TODO: Make this indexed by courseID instead of course.video_outline
@property (nullable, nonatomic, strong) NSMutableDictionary* courseVideos;

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
- (BOOL)downloadWithRequestString:(nullable NSString*)URLString forceUpdate:(BOOL)update;
- (nullable NSData*)resourceDataForURLString:(nullable NSString*)URLString downloadIfNotAvailable:(BOOL)shouldDownload;
- (void)deactivate;

// videos : OEXHelperVideoDownload
#pragma CC methods
+ (void)setCCSelectedLanguage:(NSString*)language;
+ (NSString* _Nullable)getCCSelectedLanguage;

+ (void)setCCSelectedPlaybackSpeed:(OEXVideoSpeed) speed;
+ (OEXVideoSpeed)getCCSelectedPlaybackSpeed;
+ (float) getOEXVideoSpeed:(OEXVideoSpeed) speed;

#pragma mark Last Accessed
- (OEXHelperVideoDownload* _Nullable)lastAccessedSubsectionForCourseID:(NSString*)courseID;

#pragma mark Video Management
/// videos is an array of OEXVideoSummary
- (void)addVideos:(NSArray*)videos forCourseWithID:(NSString*)courseID;
/// videos is an array of OEXHelperVideoDownload
/// This should really take a courseID not the outline URL, but that will require more serious refactoring
- (void)setVideos:(NSArray*)videos forURL:(NSString*)URLString;
- (NSString* _Nullable)URLStringForType:(NSString*)type;
- (NSMutableArray*)videosForChapterID:(NSString*)chapter
                            sectionID:(nullable NSString*)section
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
- (void)setRegisteredCourses:(NSArray<OEXCourse*>*)courses;
- (void)deleteUnregisteredItems;

#pragma mark Video Management
- (OEXHelperVideoDownload* _Nullable)stateForVideoWithID:(nullable NSString*)videoID courseID:(nullable NSString*)courseID;
- (OEXDownloadState)downloadStateForVideoWithID:(nullable NSString*)videoID;
- (OEXPlayedState)watchedStateForVideoWithID:(nullable NSString*)videoID;
- (float)lastPlayedIntervalForVideo:(OEXHelperVideoDownload*)video;
- (void)markVideoState:(OEXPlayedState)state forVideo:(OEXHelperVideoDownload*)video;
- (void)markLastPlayedInterval:(float)playedInterval forVideo:(OEXHelperVideoDownload*)video;
- (nullable NSArray*)videosOfCourseWithURLString:(nullable NSString*)URL;
- (nullable NSString*)openInBrowserLinkForCourse:(nullable OEXCourse*)course;

- (nullable NSDictionary*)processVideoSummaryList:(nullable NSData*)data URLString:(nullable NSString*)URLString;

/// @return Array of OEXVideoPathEntry
- (nullable NSArray*)chaptersForURLString:(nullable NSString*)URL;

/// @return Array of OEXVideoPathEntry
- (nullable NSArray*)sectionsForChapterID:(nullable NSString*)chapterID URLString:(nullable NSString*)URL;

#pragma mark - Closed Captioning
- (void)downloadAllTranscriptsForVideo:(nullable OEXHelperVideoDownload*)obj;

#pragma mark - Update Last Accessed from server
- (void)updateLastVisitedModule:(NSString*)module forCourseID:(NSString*)courseID;
- (void)getLastVisitedModuleForCourseID:(NSString*)courseID;
- (void)activateInterfaceForUser:(OEXUserDetails*)user;

#pragma mark - Analytics Call
- (void)sendAnalyticsEvents:(OEXVideoState)state withCurrentTime:(NSTimeInterval)currentTime forVideo:(nullable OEXHelperVideoDownload*)video;

#pragma mark - Course Enrollments
/** Finds the user's enrollment for a course */
- (nullable UserCourseEnrollment*)enrollmentForCourseWithID:(nullable NSString*)courseID;

#pragma mark - App Version
/* Return saved version of app */
- (nullable NSString*) getSavedAppVersion;

@end

@protocol OEXInterfaceProvider <NSObject>

@property (readonly, nonatomic, strong, nullable) OEXInterface* interface;

@end


NS_ASSUME_NONNULL_END
