//
//  EdXInterface.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "edXNetworkInterface.h"
#import "OEXCourse.h"
#import "OEXStorageInterface.h"

@class OEXHelperVideoDownload;
@class OEXUserDetails;

@interface OEXInterface : NSObject <EdXNetworkInterfaceDelegate, UIAlertViewDelegate>

+ (id)sharedInterface;

//Common Data

// These two indices are used to check the selected index of CC and Video Speed
// Works for both portrait and landscape mode
@property (nonatomic, assign) NSInteger selectedCCIndex;
@property (nonatomic, assign) NSInteger selectedVideoSpeedIndex;

// To pass the course and load in the next view
// Solves the waiting time issue on Course Cell clicked in FrontView
@property (nonatomic,strong) OEXCourse *selectedCourseOnFront;
@property (nonatomic,strong) OEXHelperVideoDownload *selectedVideoUsedForAnalytics;
@property (nonatomic, strong) OEXUserDetails * userdetail;
@property (nonatomic, strong) NSArray * courses;
@property (nonatomic, strong) NSMutableDictionary * courseVideos;
//Auth
@property (nonatomic, strong) NSString * signInID;
@property (nonatomic, strong) NSString * signInUserName;
@property (nonatomic, strong) NSString * signInPassword;
@property(nonatomic,assign) BOOL shownOfflineView;

//Reachability
@property (nonatomic, assign) BOOL reachable;

//Total progress
@property (nonatomic, assign) float totalProgress;
@property (nonatomic, strong) NSMutableSet * progressViews;
@property (nonatomic, assign) int numberOfRecentDownloads;

#pragma Common Methods
+ (BOOL)isURLForVideo:(NSString *)URLString;
+ (BOOL)isURLForImage:(NSString *)URLString;
+ (BOOL)isURLForedXDomain:(NSString *)URLString;


-(void)loggedInUser:(OEXUserDetails *)user;

#pragma mark Resource downloading
- (BOOL)downloadWithRequestString:(NSString *)URLString forceUpdate:(BOOL)update;
- (NSData *)resourceDataForURLString:(NSString *)URLString downloadIfNotAvailable:(BOOL)shouldDownload;
- (void)cancelDownloadWithURL:(NSString *)URLString
            completionHandler:(void (^)(BOOL success))completionHandler;
- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler; // This method get called while user logged out from app
- (void)storeVideoList:(NSArray *)videos forURL:(NSString *)URLString;


#pragma CC methods
+ (void)setCCSelectedLanguage:(NSString *)language;
+ (NSString *)getCCSelectedLanguage;


#pragma mark Last Accessed
//- (void)setLastAccessedVideoURL:(NSString *)videoURL playbackTime:(NSTimeInterval)playbackTime forCourseURL:(NSString *)courseURL;
- (OEXHelperVideoDownload *)lastAccessedSubsectionForCourseID:(NSString *)courseID;


#pragma mark Video Management
//- (DownloadState)stateForURLString:(NSString *)URLString;
//- (OEXPlayedState)watchedStateForURL:(NSString *)URLString;
//- (float)lastPlayedIntervalForURL:(NSString *)URLString;
//- (void)markVideoState:(OEXPlayedState)state forURLString:(NSString *)URLString;
//- (void)markDownloadState:(DownloadState)state forURLString:(NSString *)URLString;
//- (void)markLastPlayedInterval:(float)playedInterval forURL:(NSString *)URLString;
- (NSString *)URLStringForType:(NSString *)type;
- (NSMutableArray *)videosForChaptername:(NSString *)chapter
                  andSectionName:(NSString *)section
                          forURL:(NSString *)URLString;

- (NSMutableArray *)coursesAndVideosForDownloadState:(OEXDownloadState)state;
- (NSArray *)allVideosForState:(OEXDownloadState)state;


#pragma mark Wifi Only

+ (BOOL)shouldDownloadOnlyOnWifi;
+ (void)setDownloadOnlyOnWifiPref:(BOOL)should;
//+ (void)clearSession;

#pragma mark - Bulk Download

- (float)showBulkProgressViewForChapter:(NSString *)strChapName andSectionName:(NSString *)section;
/*
 New methods for refactoring
 */
// Download  video
-(void)startDownloadForVideo:(OEXHelperVideoDownload *)video completionHandler:(void(^)(BOOL sucess))completionHandler;
// Cancel Video download
-(void)cancelDownloadForVideo:(OEXHelperVideoDownload *)video completionHandler:(void (^)(BOOL))completionHandler;
// Array contains HelperVideoDownload objects
- (NSInteger)downloadMultipleVideosForObjects:(NSArray *)array;
// Start All paused downloads
- (void)startAllBackgroundDownloads;

- (NSInteger)downloadMultipleVideosForRequestStrings:(NSArray *)array;

- (void)deleteDownloadedVideoForVideoId:(NSString *)videoId completionHandler:(void (^)(BOOL success))completionHandler ;

- (VideoData *)insertVideoData:(OEXHelperVideoDownload *)helperVideo;


#pragma mark- For Refresh of all Courses.

- (void)setAllEntriesUnregister;

- (void)setRegisterCourseForCourseID:(NSString *)courseid;

- (void)deleteUnregisteredItems;




#pragma mark Last Accessed Video
//-(void)setLastAccessedVideo:(HelperVideoDownload *)video forCourseURL:(NSString *)courseURL;
//- (HelperVideoDownload *)lastAccessedVideoURLForCourse:(Course *)course;

#pragma mark Video Management
-(OEXDownloadState)stateForVideo:(OEXHelperVideoDownload *)video;
-(OEXPlayedState)watchedStateForVideo:(OEXHelperVideoDownload *)video;
- (float)lastPlayedIntervalForVideo:(OEXHelperVideoDownload *)video;
- (void)markVideoState:(OEXPlayedState)state forVideo:(OEXHelperVideoDownload *)video;
- (void)markDownloadState:(OEXDownloadState)state forVideo:(OEXHelperVideoDownload *)video;
- (void)markLastPlayedInterval:(float)playedInterval forVideo:(OEXHelperVideoDownload *)video;

//- (NSString *)URLStringForType:(NSString *)type;
//- (void)startAllBackgroundDownloads;
//- (NSMutableArray *)videosForChaptername:(NSString *)chapter andSectionName:(NSString *)section forURL:(NSString *)URLString;

//- (NSMutableArray *)coursesAndVideosForDownloadState:(DownloadState)state;
//- (NSArray *)allVideosForState:(DownloadState)state;


#pragma mark - Closed Captioning

- (void)downloadTranscripts:(OEXHelperVideoDownload *)obj;

#pragma mark - Update Last Accessed from server

- (void)updateLastVisitedModule:(NSString*)module;
- (void)getLastVisitedModule;


-(void)activateIntefaceForUser:(OEXUserDetails *)user;



#pragma mark - Analytics Call
- (void)sendAnalyticsEvents:(OEXVideoState)state WithCurrentTime:(NSTimeInterval)currentTime;


@end
