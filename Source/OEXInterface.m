//
//  EdXInterface.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

@import edXCore;

#import "OEXInterface.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "NSArray+OEXFunctional.h"
#import "NSArray+OEXSafeAccess.h"
#import "NSJSONSerialization+OEXSafeAccess.h"
#import "NSNotificationCenter+OEXSafeAccess.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXCourse.h"
#import "OEXDataParser.h"
#import "OEXDownloadManager.h"
#import "OEXFileUtility.h"
#import "OEXHelperVideoDownload.h"
#import "OEXNetworkConstants.h"
#import "OEXSession.h"
#import "OEXStorageFactory.h"
#import "OEXUserDetails.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"
#import "Reachability.h"
#import "VideoData.h"

NSString* const OEXCourseListChangedNotification = @"OEXCourseListChangedNotification";
NSString* const OEXCourseListKey = @"OEXCourseListKey";

NSString* const OEXVideoStateChangedNotification = @"OEXVideoStateChangedNotification";
NSString* const OEXDownloadProgressChangedNotification = @"OEXDownloadProgressChangedNotification";
NSString* const OEXDownloadEndedNotification = @"OEXDownloadEndedNotification";
NSString* const OEXSavedAppVersionKey = @"OEXSavedAppVersionKey";

@interface OEXInterface () <OEXDownloadManagerProtocol>

@property (nonatomic, strong) OEXNetworkInterface* network;
@property (nonatomic, strong) OEXDataParser* parser;
@property(nonatomic, weak) OEXDownloadManager* downloadManger;

//Cached Data
@property (nonatomic, assign) int commonDownloadProgress;

@property (nonatomic, strong) NSArray<OEXHelperVideoDownload*>* multipleDownloadArray;

@property(nonatomic, strong) NSTimer* timer;

@property (nonatomic, strong, nullable) NSArray<UserCourseEnrollment*>* courses;
@property (nonatomic, strong, nullable) NSMutableDictionary* courseVideos;

@end

static OEXInterface* _sharedInterface = nil;

@implementation OEXInterface

#pragma mark Initialization

+ (id)sharedInterface {
    if(!_sharedInterface) {
        _sharedInterface = [[OEXInterface alloc] init];
    }
    return _sharedInterface;
}

- (id)init {
    self = [super init];
    //Reachability
    self.reachable = YES;
    ///Total progress views
    self.progressViews = [[NSMutableSet alloc] init];

    //Listen to download notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:DL_COMPLETE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoDownloadComplete:)
                                                 name:OEXDownloadEndedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressNotification:) name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionStartedNotification action:^(NSNotification *notification, OEXInterface* observer, id<OEXRemovable> removable) {
        OEXUserDetails* user = notification.userInfo[OEXSessionStartedUserDetailsKey];
        [observer activateInterfaceForUser:user];
    }];

    [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionEndedNotification action:^(NSNotification * _Nonnull notification, id  _Nonnull observer, id<OEXRemovable>  _Nonnull removable) {
        [observer deactivate];
    }];

    [self firstLaunchWifiSetting];
    [self saveAppVersion];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)backgroundInit {
    //course details
    self.courses = [self parsedObjectWithData:[self resourceDataForURLString:[_network URLStringForType:URL_COURSE_ENROLLMENTS] downloadIfNotAvailable:NO] forURLString:[_network URLStringForType:URL_COURSE_ENROLLMENTS]];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self resumePausedDownloads];
    }];
}

#pragma mark common methods

- (OEXCourse*)courseWithID:(NSString *)courseID {
    for(UserCourseEnrollment* enrollment in self.courses) {
        if([enrollment.course.course_id isEqual:courseID]) {
            return enrollment.course;
        }
    }
    return nil;
}

- (id)parsedObjectWithData:(NSData*)data forURLString:(NSString*)URLString {
    if(!data) {
        //NSLog(@"Empty data sent for parsing!");
        return nil;
    }

    if([URLString isEqualToString:[self URLStringForType:URL_USER_DETAILS]]) {
        return [self.parser userDetailsWithData:data];
    }
    else if([URLString isEqualToString:[self URLStringForType:URL_COURSE_ENROLLMENTS]]) {
        return [self.parser userCourseEnrollmentsWithData:data];
    }
    else if([URLString rangeOfString:URL_COURSE_ANNOUNCEMENTS].location != NSNotFound) {
        return [self.parser announcementsWithData:data];
    }
    else if([URLString rangeOfString:URL_COURSE_HANDOUTS].location != NSNotFound) {
        return [self.parser handoutsWithData:data];
    }

    return nil;
}

- (NSString*)URLStringForType:(NSString*)type {
    NSMutableString* URLString = [NSMutableString stringWithString:[OEXConfig sharedConfig].apiHostURL.absoluteString];

    if([type isEqualToString:URL_USER_DETAILS]) {
        [URLString appendFormat:@"%@/%@", URL_USER_DETAILS, [OEXSession sharedSession].currentUser.username];
    }
    else if([type isEqualToString:URL_COURSE_ENROLLMENTS]) {
        [URLString appendFormat:@"%@/%@%@", URL_USER_DETAILS, [OEXSession sharedSession].currentUser.username, URL_COURSE_ENROLLMENTS];
    }
    else {
        return nil;
    }
    //Append tail
    [URLString appendString:@"?format=json"];

    return URLString;
}

+ (BOOL)isURLForVideo:(NSString*)URLString {
    for (NSString *extension_option in VIDEO_URL_EXTENSION_OPTIONS) {
        // Check each string in VIDEO_URL_EXTENSION_OPTIONS to see if the URL has a valid file extension for a video
        if([URLString localizedCaseInsensitiveContainsString:extension_option]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isURLForImage:(NSString*)URLString {
    if([URLString rangeOfString:URL_SUBSTRING_ASSETS].location != NSNotFound) {
        return YES;
    }
    return NO;
}

- (void)createDatabaseDirectory {
    [_storage createDatabaseDirectory];
}

#pragma mark Wifi Only

- (void)firstLaunchWifiSetting {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if(![userDefaults objectForKey:USERDEFAULT_KEY_WIFIONLY]) {
        [userDefaults setBool:YES forKey:USERDEFAULT_KEY_WIFIONLY];
    }
}

+ (BOOL)shouldDownloadOnlyOnWifi {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL should = [userDefaults boolForKey:USERDEFAULT_KEY_WIFIONLY];
    return should;
}

- (BOOL)shouldDownloadOnlyOnWifi {
    return [[self class] shouldDownloadOnlyOnWifi];
}

+ (void)setDownloadOnlyOnWifiPref:(BOOL)should {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:should forKey:USERDEFAULT_KEY_WIFIONLY];
    [userDefaults synchronize];
}

#pragma mark public methods
- (void)setNumberOfRecentDownloads:(int)numberOfRecentDownloads {
    _numberOfRecentDownloads = numberOfRecentDownloads;
    if([OEXSession sharedSession].currentUser.username) {
        NSString* key = [NSString stringWithFormat:@"%@_numberOfRecentDownloads", [OEXSession sharedSession].currentUser.username];
        [[NSUserDefaults standardUserDefaults] setInteger:_numberOfRecentDownloads forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Persist the CC selected Language

+ (void)setCCSelectedLanguage:(NSString*)language {
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:PERSIST_CC];
}

+ (NSString*)getCCSelectedLanguage {
    return [[NSUserDefaults standardUserDefaults] objectForKey:PERSIST_CC];
}

#pragma mark - Persist the CC selected Video Speed

+ (void)setCCSelectedPlaybackSpeed:(OEXVideoSpeed) speed {
    [[NSUserDefaults standardUserDefaults] setInteger:speed forKey:PERSIST_PLAYBACKSPEED];
}

+ (OEXVideoSpeed)getCCSelectedPlaybackSpeed {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PERSIST_PLAYBACKSPEED];
}

+ (float) getOEXVideoSpeed:(OEXVideoSpeed) speed {
    switch (speed) {
        case OEXVideoSpeedDefault:
            return 1.0;
            break;
        case OEXVideoSpeedSlow:
            return 0.5;
        case OEXVideoSpeedFast:
            return 1.5;
        case OEXVideoSpeedXFast:
            return 2.0;
        default:
            return 1.0;
            break;
    }
}

#pragma common Network Calls

- (void)startAllBackgroundDownloads {
    //If entering common download mode
    if(_commonDownloadProgress == -1) {
        self.commonDownloadProgress = 0;
    }
    [self downloadNextItem];
}

- (void)downloadNextItem {
    switch(_commonDownloadProgress) {
        case 0:
            [self downloadWithRequestString:URL_USER_DETAILS forceUpdate:YES];
            break;
        case 1:
            [self downloadWithRequestString:URL_COURSE_ENROLLMENTS forceUpdate:YES];
            break;
        default:
            _commonDownloadProgress = -1;
            break;
    }
}

#pragma mark Public

- (void)requestWithRequestString:(NSString*)URLString {
    //Network Request
    [_network callRequestString:URLString];
}
// This method Start Downloads for resources
- (BOOL)downloadWithRequestString:(NSString*)URLString forceUpdate:(BOOL)update {
    if(!_reachable || [OEXInterface isURLForVideo:URLString]) {
        return NO;
    }

    if([URLString isEqualToString:URL_USER_DETAILS]) {
        URLString = [_network URLStringForType:URL_USER_DETAILS];
    }
    else if([URLString isEqualToString:URL_COURSE_ENROLLMENTS]) {
        URLString = [_network URLStringForType:URL_COURSE_ENROLLMENTS];
    }
    else if([URLString rangeOfString:URL_VIDEO_SRT_FILE].location != NSNotFound) {      // For Closed Captioning
        [_network downloadWithURLString:URLString];
    }
    else if([OEXInterface isURLForImage:URLString]) {
        return NO;
    }

    NSString* filePath = [OEXFileUtility filePathForRequestKey:URLString];

    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [_network downloadWithURLString:URLString];
    }
    else {
        if(update) {
            //Network Request
            [_network downloadWithURLString:URLString];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                                object:self
                                                              userInfo:@{NOTIFICATION_KEY_URL: URLString,
                                                                         NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_SUCCESS,
                                                                         NOTIFICATION_KEY_OFFLINE: NOTIFICATION_VALUE_OFFLINE_NO, }];
        }
    }
    return YES;
}

- (BOOL)canDownloadVideos:(NSArray*)videos {
    double totalSpaceRequired = 0;
    //Total space
    for(OEXHelperVideoDownload* video in videos) {
        totalSpaceRequired += [video.summary.size doubleValue];
    }
    totalSpaceRequired = totalSpaceRequired / 1024 / 1024 / 1024;
    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([OEXInterface shouldDownloadOnlyOnWifi]) {
        if(![appD.reachability isReachableViaWiFi]) {
            return NO;
        }
    }
    
    if(totalSpaceRequired > 1) {
        self.multipleDownloadArray = videos;
        
        // As suggested by Lou
        UIAlertView* alertView =
            [[UIAlertView alloc] initWithTitle:[Strings largeDownloadTitle]
                                       message:[Strings largeDownloadMessage]
                                      delegate:self
                             cancelButtonTitle:[Strings cancel]
                             otherButtonTitles:[Strings acceptLargeVideoDownload], nil];
        
        [alertView show];
        return NO;
    }
    return YES;
}

- (NSInteger)downloadVideos:(NSArray<OEXHelperVideoDownload*>*)array {
    BOOL isValid = [self canDownloadVideos:array];
    
    if(!isValid) {
        return 0;
    }
    
    NSInteger count = 0;
    for(OEXHelperVideoDownload* video in array) {
        if(video.summary.downloadURL.length > 0 && video.downloadState == OEXDownloadStateNew) {
            [self downloadAllTranscriptsForVideo:video];
            [self addVideoForDownload:video completionHandler:^(BOOL success){}];
            count++;
        }
    }
    return count;
}

- (NSArray<OEXHelperVideoDownload*>*)statesForVideosWithIDs:(NSArray<NSString*>*)videoIDs courseID:(NSString*)courseID {
    NSMutableDictionary* videos = [[NSMutableDictionary alloc] init];
    OEXCourse* course = [self courseWithID:courseID];
    
    for(OEXHelperVideoDownload* video in [self.courseVideos objectForKey:course.video_outline]) {
        [videos setSafeObject:video forKey:video.summary.videoID];
    }
    return [videoIDs oex_map:^id(NSString* videoID) {
        return [videos objectForKey:videoID];
    }];
}

- (NSInteger)downloadVideosWithIDs:(NSArray*)videoIDs courseID:(NSString*)courseID {
    NSArray* videos = [self statesForVideosWithIDs:videoIDs courseID:courseID];
    return [self downloadVideos:videos];
}

- (NSData*)resourceDataForURLString:(NSString*)URLString downloadIfNotAvailable:(BOOL)shouldDownload {
    NSData* data = [_storage dataForURLString:URLString];
    //If data is not downloaded, start download
    if(!data && shouldDownload) {
        [self downloadWithRequestString:URLString forceUpdate:NO];
    }
    return data;
}

- (float)lastPlayedIntervalForURL:(NSString*)URLString {
    return 0;
}

- (float)lastPlayedIntervalForVideoID:(NSString*)videoID {
    return [_storage lastPlayedIntervalForVideoID:videoID];
}

- (void)markLastPlayedInterval:(float)playedInterval forVideoID:(NSString*)videoId {
    if(playedInterval <= 0) {
        return;
    }
    [_storage markLastPlayedInterval:playedInterval forVideoID:videoId];
}

- (void)deleteDownloadedVideo:(OEXHelperVideoDownload *)video completionHandler:(void (^)(BOOL success))completionHandler {
    [_storage deleteDataForVideoID:video.summary.videoID];
    video.downloadState = OEXDownloadStateNew;
    video.downloadProgress = 0.0;
    video.isVideoDownloading = false;
    completionHandler(YES);
}

- (void)deleteDownloadedVideos:(NSArray *)videos completionHandler:(void (^)(BOOL success))completionHandler {
    for (OEXHelperVideoDownload *video in videos) {
        [self deleteDownloadedVideo:video completionHandler:^(BOOL success) {}];
    }
    completionHandler(YES);
}

- (void)setAllEntriesUnregister {
    [_storage unregisterAllEntries];
}

- (void)setRegisteredCourses:(NSArray*)courses {
    NSMutableSet* courseIDs = [[NSMutableSet alloc] init];
    for(OEXCourse* course in courses) {
        if(course.course_id != nil) {
            [courseIDs addObject:course.course_id];
        }
    }
    
    NSArray* videos = [self.storage getAllLocalVideoData];
    for(VideoData* video in videos) {
        if([courseIDs containsObject:video.enrollment_id]) {
            video.is_registered = [NSNumber numberWithBool:YES];
        }
    }
    [self.storage saveCurrentStateToDB];

    NSDictionary* userInfo = @{
                               OEXCourseListKey : [NSArray arrayWithArray:courses]
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:OEXCourseListChangedNotification object:nil userInfo:userInfo];
}

- (void)deleteUnregisteredItems {
    [_storage deleteUnregisteredItems];
}

- (VideoData*)insertVideoData:(OEXHelperVideoDownload*)helperVideo {
    return [_storage insertVideoData: @""
                               Title: helperVideo.summary.name
                                Size: [NSString stringWithFormat:@"%.2f", [helperVideo.summary.size doubleValue]]
                            Duration: [NSString stringWithFormat:@"%.2f", helperVideo.summary.duration]
                       DownloadState: helperVideo.downloadState
                            VideoURL: helperVideo.summary.downloadURL
                             VideoID: helperVideo.summary.videoID
                             UnitURL: helperVideo.summary.unitURL
                            CourseID: helperVideo.course_id
                                DMID: 0
                         ChapterName: helperVideo.summary.chapterPathEntry.name
                         SectionName: helperVideo.summary.sectionPathEntry.name
                           TimeStamp: nil
                      LastPlayedTime: helperVideo.lastPlayedInterval
                              is_Reg: YES
                         PlayedState: helperVideo.watchedState];
}

#pragma mark Last Accessed

- (OEXHelperVideoDownload*)lastAccessedSubsectionForCourseID:(NSString*)courseID {
    LastAccessed* lastAccessed = [_storage lastAccessedDataForCourseID:courseID];

    if(lastAccessed.course_id) {
        for(UserCourseEnrollment* courseEnrollment in _courses) {
            OEXCourse* course = courseEnrollment.course;

            if([courseID isEqualToString:course.course_id]) {
                for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
                    OEXLogInfo(@"LAST ACCESSED", @"video.subSectionID : %@", video.summary.sectionPathEntry.entryID);
                    OEXLogInfo(@"LAST ACCESSED", @"lastAccessed.subsection_id : %@ \n *********************\n", lastAccessed.subsection_id);

                    if([video.summary.sectionPathEntry.entryID isEqualToString:lastAccessed.subsection_id]) {
                        return video;
                    }
                }
            }
        }
    }

    return nil;
}

#pragma mark Update Storage

- (void)updateWithData:(NSData*)data
      forRequestString:(NSString*)URLString {
    [_storage updateData:data ForURLString:URLString];
}

#pragma mark EdxNetworkInterface Delegate

- (void)updateTotalProgress {
    NSArray* array = [self allVideosForState:OEXDownloadStatePartial];
    float total = 0;
    float done = 0;
    for(OEXHelperVideoDownload* video in array) {
        total += OEXMaxDownloadProgress;
        done += video.downloadProgress;
    }

    BOOL viewHidden = YES;

    if(total > 0) {
        self.totalProgress = (float)done / (float)total;
        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            [[NSNotificationCenter defaultCenter] postNotificationName:OEXDownloadProgressChangedNotification object:nil];
        }
        //show circular views
        viewHidden = NO;
    }
    else {
        viewHidden = YES;
        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive && self.totalProgress != 0) {
            self.totalProgress = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:OEXDownloadEndedNotification object:nil];
        }
    }

    if(!_reachable && !viewHidden) {
        viewHidden = YES;
    }

    for(UIView* view in _progressViews) {
        view.hidden = viewHidden;
    }
}

#pragma mark notification methods

- (void)downloadCompleteNotification:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;

    NSURLSessionTask* task = [dict objectForKey:DL_COMPLETE_N_TASK];
    NSURL* url = task.originalRequest.URL;

    NSData* data = [self resourceDataForURLString:url.absoluteString downloadIfNotAvailable:NO];
    [self returnedData:data forType:url.absoluteString];
}

- (void)videoDownloadComplete:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;
    NSURLSessionTask* task = [dict objectForKey:OEXDownloadEndedNotification];
    NSURL* url = task.originalRequest.URL;
    if([OEXInterface isURLForVideo:url.absoluteString]) {
        self.numberOfRecentDownloads++;
        [self markDownloadProgress:OEXMaxDownloadProgress forURL:url.absoluteString andVideoId:nil];
    }
}

- (void)downloadProgressNotification:(NSNotification*)notification {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            NSDictionary* dictProgress = (NSDictionary*)notification.userInfo;
            NSURLSessionTask* task = [dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TASK];
            NSString* url = [task.originalRequest.URL absoluteString];
            double totalBytesWritten = [[dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN] doubleValue];
            double totalBytesExpectedToWrite = [[dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE] doubleValue];
            
            double completed = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            float completedPercent = completed * OEXMaxDownloadProgress;
            [weakSelf markDownloadProgress:completedPercent forURL:url andVideoId:nil];
    });
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    id <Reachability> reachability = [notification object];

    if([reachability isReachable]) {
        self.reachable = YES;

        // TODO: Resume downloads on network availability
        // [self resumePausedDownloads];
    }
    else {
        self.reachable = NO;
    }
}

#pragma mark NetworkInterface Delegate
- (void)returnedData:(NSData*)data forType:(NSString*)URLString {
    //Update Storage
    [self updateWithData:data forRequestString:URLString];

    //Parse and return
    [self processData:data forType:URLString usingOfflineCache:NO];
}

- (void)returnedFailureForType:(NSString*)URLString {
    //VIDEO URL
    if([OEXInterface isURLForVideo:URLString]) {
    }
    else {
        //look for cached response
        NSData* data = [_storage dataForURLString:URLString];
        if(data) {
            [self processData:data forType:URLString usingOfflineCache:YES];
        }
        else {
            //Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                                object:self
                                                              userInfo:@{NOTIFICATION_KEY_URL: URLString,
                                                                         NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_FAILED}];
        }
    }
}

- (void)didAddDownloadForURLString:(NSString*)URLString {
}

- (void)didRejectDownloadForURLString:(NSString*)URLString {
}

#pragma mark Video management
- (void)markDownloadProgress:(float)progress forURL:(NSString*)URLString andVideoId:(NSString*)videoId {
    @autoreleasepool {
        for(OEXHelperVideoDownload* video in [self allVideos]) {
            if(([video.summary.downloadURL isEqualToString:URLString] && video.downloadState == OEXDownloadStatePartial)
               || [video.summary.videoID isEqualToString:videoId]) {
                video.downloadProgress = progress;
                video.isVideoDownloading = YES;
                if(progress == OEXMaxDownloadProgress) {
                    video.downloadState = OEXDownloadStateComplete;
                    video.isVideoDownloading = NO;
                    video.completedDate = [NSDate date];
                }
                else if(progress > 0) {
                    video.downloadState = OEXDownloadStatePartial;
                }
                else {
                    video.downloadState = OEXDownloadStateNew;
                    video.isVideoDownloading = NO;
                }
            }
        }
    }
}

#pragma Video liast manangement

- (void)processData:(NSData*)data forType:(NSString*)URLString usingOfflineCache:(BOOL)offline {
    //Check if data type needs parsing
    if([OEXInterface isURLForVideo:URLString]) {
        return;
    }
    else if([OEXInterface isURLForImage:URLString]) {
    }
    else {
        //Get object
        id object = [self parsedObjectWithData:data forURLString:URLString];
        if(!object) {
            return;
        }

        //download any additional data if required
        else if([URLString isEqualToString:[self URLStringForType:URL_COURSE_ENROLLMENTS]]) {
            self.courses = (NSArray*)object;
            for(UserCourseEnrollment* courseEnrollment in _courses) {
                OEXCourse* course = courseEnrollment.course;

                //course enrolments, get images for background
                NSString* courseImage = course.courseImageURL;
                NSString* imageDownloadURL = [NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, courseImage];

                BOOL force = NO;
                if(_commonDownloadProgress != -1) {
                    force = YES;
                }

                [self downloadWithRequestString:imageDownloadURL forceUpdate:force];

                //course subsection
                NSString* courseVideoDetails = course.video_outline;
                [self downloadWithRequestString:courseVideoDetails forceUpdate:force];
            }
        }

        //If not using common download mode
        if(_commonDownloadProgress == -1) {
            //Delegate call back
        }
        else {
            _commonDownloadProgress++;
            [self downloadNextItem];
        }
    }

    //Post notification
    NSString* offlineValue = NOTIFICATION_VALUE_OFFLINE_NO;
    if(offline) {
        offlineValue = NOTIFICATION_VALUE_OFFLINE_YES;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                        object:self
                                                      userInfo:@{NOTIFICATION_KEY_URL: URLString,
                                                                 NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_SUCCESS,
                                                                 NOTIFICATION_KEY_OFFLINE: offlineValue, }];
}

- (void)makeRecordsForVideos:(NSArray*)videos inCourse:(OEXCourse*)course {
    NSMutableDictionary* dictVideoData = [[NSMutableDictionary alloc] init];
    /// Added for debugging
    int partiallyDownloaded = 0;
    int newVideos = 0;
    int downloadCompleted = 0;
    
    NSArray* array = [_storage getAllLocalVideoData];
    for(VideoData* videoData in array) {
        if(videoData.video_id) {
            [dictVideoData setObject:videoData forKey:videoData.video_id];
        }
    }
    
    //Check in DB
    for(OEXHelperVideoDownload* video in videos) {
        VideoData* data = [dictVideoData objectForKey:video.summary.videoID];
        
        OEXDownloadState downloadState = [data.download_state intValue];
        
        video.course_id = course.course_id;
        video.course_url = course.video_outline;
        
        if(!data) {
            downloadState = OEXDownloadStateNew;
            video.watchedState = OEXPlayedStateUnwatched;
            video.lastPlayedInterval = 0;
        }
        else {
            video.watchedState = [data.played_state intValue];
            video.lastPlayedInterval = [data.last_played_offset integerValue];
        }
        switch(downloadState) {
            case OEXDownloadStateNew:
                video.isVideoDownloading = NO;
                newVideos++;
                break;
            case OEXDownloadStatePartial:
                video.isVideoDownloading = YES;
                video.downloadProgress = 1.0;
                partiallyDownloaded++;
                break;
            default:
                video.isVideoDownloading = YES;
                video.downloadProgress = OEXMaxDownloadProgress;
                video.completedDate = data.downloadCompleteDate;
                downloadCompleted++;
                break;
        }
        video.downloadState = downloadState;
    }

}

- (void)addVideos:(NSArray*)videos forCourseWithID:(NSString*)courseID {
    OEXCourse* course = [self courseWithID:courseID];
    NSMutableArray* videoDatas = [[_courseVideos objectForKey:course.video_outline] mutableCopy];
    NSMutableSet* knownVideoIDs = [[NSMutableSet alloc] init];
    NSMutableDictionary* videosMap = [[NSMutableDictionary alloc] init];
    if(videoDatas == nil) {
        // we don't have any videos for this course yet
        // so set it up
        videoDatas = [[NSMutableArray alloc] init];
        [self.courseVideos setSafeObject:videoDatas forKey:course.video_outline];
    }
    else {
        // we do have videos, so collect their IDs so we only add new ones
        for(OEXHelperVideoDownload* download in videoDatas) {
            [knownVideoIDs addObject:download.summary.videoID];
            [videosMap setSafeObject:download forKey:download.summary.videoID];
        }
    }
    
    NSArray* videoHelpers = [videos oex_map:^id(OEXVideoSummary* summary) {
        if(![knownVideoIDs containsObject:summary.videoID]) {
            OEXHelperVideoDownload* helper = [[OEXHelperVideoDownload alloc] init];
            helper.summary = summary;
            helper.filePath = [OEXFileUtility filePathForRequestKey:summary.downloadURL];
            [videoDatas addObject:helper];
            return helper;
        }
        else {
            OEXHelperVideoDownload* helper = [videosMap objectForKey:summary.videoID];
            // Hack
            // Duration doesn't always come through the old API for some reason, so make here we make sure
            // it's set from the new content.
            // But we don't actually need to make a record for it so don't return it
            // TODO: Short term: Update the video summary in the new API to get all its properties from block
            // TODO: Long term: Get the video module to take a block as its input
            helper.summary.duration = summary.duration;
            helper.summary.encodings = summary.encodings;
            
            return nil;
        }
    }];
    
    [self.courseVideos setSafeObject:videoDatas forKey:course.video_outline];
    
    [self makeRecordsForVideos:videoHelpers inCourse:course];
}

- (NSMutableArray*)coursesAndVideosForDownloadState:(OEXDownloadState)state {
    NSMutableArray* mainArray = [[NSMutableArray alloc] init];

    for(UserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;
        //Videos array
        NSMutableArray* videosArray = [[NSMutableArray alloc] init];

        for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
            //Complete
            if(video.downloadState == OEXDownloadStateComplete && state == OEXDownloadStateComplete) {
                [videosArray addObject:video];
            }
            //Partial
            else if(video.downloadState == OEXDownloadStatePartial && video.downloadProgress < OEXMaxDownloadProgress && state == OEXDownloadStatePartial) {
                [videosArray addObject:video];
            }
            else if(video.downloadState == OEXDownloadStateNew && OEXDownloadStateNew) {
//                [videosArray addObjectr:video];
            }
        }

        if(videosArray.count > 0) {
            NSDictionary* dict = @{CAV_KEY_COURSE:course,
                                   CAV_KEY_VIDEOS:videosArray};
            [mainArray addObject:dict];
        }
    }
    return mainArray;
}

- (NSArray*)allVideos {
    NSMutableArray* mainArray = [[NSMutableArray alloc] init];

    for(UserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;

        for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
            [mainArray addObject:video];
        }
    }

    return mainArray;
}

- (OEXHelperVideoDownload*)getSubsectionNameForSubsectionID:(NSString*)subsectionID {
    for(UserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;

        for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
            if([video.summary.sectionPathEntry.entryID isEqualToString:subsectionID]) {
                return video;
            }
        }
    }

    return nil;
}

- (NSArray*)allVideosForState:(OEXDownloadState)state {
    NSMutableArray* mainArray = [[NSMutableArray alloc] init];

    for(UserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;

        for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
            //Complete
            if((video.downloadProgress == OEXMaxDownloadProgress) && (state == OEXDownloadStateComplete)) {
                [mainArray addObject:video];
            }
            //Partial
            else if((video.isVideoDownloading && (video.downloadProgress < OEXMaxDownloadProgress)) && (state == OEXDownloadStatePartial)) {
                [mainArray addObject:video];
            }
            else if(!video.isVideoDownloading && (state == OEXDownloadStateNew)) {
                [mainArray addObject:video];
            }
        }
    }

    return mainArray;
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        NSInteger count = [self downloadVideos:_multipleDownloadArray];
        if(count > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FL_MESSAGE
                                                                object:self
                                                              userInfo:@{FL_ARRAY: _multipleDownloadArray}];
        }
    }
    else {
        self.multipleDownloadArray = nil;
    }
}

#pragma mark - Closed Captioning
- (void)downloadAllTranscriptsForVideo:(OEXHelperVideoDownload*)videoDownloadHelper;
{
    //Download All Transcripts
    [[videoDownloadHelper.summary transcripts] enumerateKeysAndObjectsUsingBlock:^(NSString* language, NSString* url, BOOL *stop) {
        NSData* data = [self resourceDataForURLString:url downloadIfNotAvailable:NO];
        if (!data) {
            [self downloadWithRequestString:url forceUpdate:YES];
        }
    }];
}

#pragma mark - Download Video

- (void)startDownloadForVideo:(OEXHelperVideoDownload*)video completionHandler:(void (^)(BOOL sucess))completionHandler {
    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([OEXInterface isURLForVideo:video.summary.downloadURL]) {
        if([OEXInterface shouldDownloadOnlyOnWifi]) {
            if(![appD.reachability isReachableViaWiFi]) {
                completionHandler(NO);
                return;
            }
        }
    }
    [self addVideoForDownload:video completionHandler:completionHandler];
}

- (void)addVideoForDownload:(OEXHelperVideoDownload*)video completionHandler:(void (^)(BOOL sucess))completionHandler {
    __block VideoData* data = [_storage videoDataForVideoID:video.summary.videoID];
    if(!data || !data.video_url) {
        data = [self insertVideoData:video];
    }

    NSArray* array = [_storage getVideosForDownloadUrl:video.summary.downloadURL];
    if([array count] > 1) {
        for(VideoData* videoObj in array) {
            if([videoObj.download_state intValue] == OEXDownloadStateComplete) {
                [_storage completedDownloadForVideo:data];
                video.downloadProgress = OEXMaxDownloadProgress;
                video.isVideoDownloading = NO;
                video.downloadState = OEXDownloadStateComplete;
                completionHandler(YES);
                return;
            }
        }
    }

    if(data) {
        [[OEXDownloadManager sharedManager] downloadVideoForObject:data withCompletionHandler:^(NSURLSessionDownloadTask* downloadTask) {
            if(downloadTask) {
                video.downloadState = OEXDownloadStatePartial;
                video.downloadProgress = 0.1;
                video.isVideoDownloading = YES;
                completionHandler(YES);
            }
            else {
                completionHandler(NO);
            }
        }];
    }
}

// Cancel Video download
- (void)cancelDownloadForVideo:(OEXHelperVideoDownload*)video completionHandler:(void (^) (BOOL))completionHandler {
    VideoData* data = [_storage videoDataForVideoID:video.summary.videoID];

    if(data) {
        [[OEXDownloadManager sharedManager] cancelDownloadForVideo:data completionHandler:^(BOOL success) {
            video.downloadState = OEXDownloadStateNew;
            video.downloadProgress = 0;
            video.isVideoDownloading = NO;
            completionHandler(success);
        }];
    }
    else {
        video.isVideoDownloading = NO;
        video.downloadProgress = 0;
        video.downloadState = OEXDownloadStateNew;
    }
}

- (void)resumePausedDownloads {
    [_downloadManger resumePausedDownloads];
}

- (void)t_setCourseEnrollments:(NSArray *)courses
{
    self.courses = courses;
}

- (void)t_setCourseVideos:(NSDictionary *)courseVideos
{
    self.courseVideos = [courseVideos copy];
}

#pragma mark Video Management

- (OEXHelperVideoDownload*)stateForVideoWithID:(NSString*)videoID courseID:(NSString*)courseID {
    // This being O(n) is pretty mediocre
    // We should rebuild this to have all the videos in a hash table
    // Right now they actually need to be in an array since that is
    // how we decide their order in the UI.
    // But once we switch to the new course structure endpoint, that will no longer be the case
    OEXCourse* course = [self courseWithID:courseID];
    for(OEXHelperVideoDownload* video in [self.courseVideos objectForKey:course.video_outline]) {
        if([video.summary.videoID isEqual:videoID]) {
            return video;
        }
    }
    return nil;
}

- (OEXDownloadState)downloadStateForVideoWithID:(NSString*)videoID {
    return [self.storage videoStateForVideoID:videoID];
}

- (OEXPlayedState)watchedStateForVideoWithID:(NSString*)videoID {
    return [self.storage watchedStateForVideoID:videoID];
}

- (float)lastPlayedIntervalForVideo:(OEXHelperVideoDownload*)video {
    return [_storage lastPlayedIntervalForVideoID:video.summary.videoID];
}

- (void)markVideoState:(OEXPlayedState)state forVideo:(OEXHelperVideoDownload*)video {
    for(OEXHelperVideoDownload* videoObj in [self allVideos]) {
        if([videoObj.summary.videoID isEqualToString:video.summary.videoID]) {
            videoObj.watchedState = state;
            [self.storage markPlayedState:state forVideoID:video.summary.videoID];
            [[NSNotificationCenter defaultCenter] postNotificationName:OEXVideoStateChangedNotification object:videoObj];
        }
    }
}

- (void)markLastPlayedInterval:(float)playedInterval forVideo:(OEXHelperVideoDownload*)video {
    [_storage markLastPlayedInterval:playedInterval forVideoID:video.summary.videoID];
}

#pragma mark DownloadManagerDelegate

- (void)downloadTaskDidComplete:(NSURLSessionDownloadTask*)task {
}

- (void)downloadTask:(NSURLSessionDownloadTask*)task didCOmpleteWithError:(NSError*)error {
    NSArray* array = [_storage videosForTaskIdentifier:task.taskIdentifier];
    for(VideoData* video in array) {
        video.dm_id = [NSNumber numberWithInt:0];
        video.download_state = [NSNumber numberWithInt:OEXDownloadStateNew];
    }
    [self markDownloadProgress:0.0 forURL:[task.originalRequest.URL absoluteString] andVideoId:nil];

    [_storage saveCurrentStateToDB];
}

- (void)downloadAlreadyInProgress:(NSURLSessionDownloadTask*)task {
}

#pragma mark - Update Last Accessed from server

// Request Body

//ISO 8601 international standard date format
/*
 {
    @"modification_date" :@"2014-11-20 22:10:54.569200+00:00"
    @"last_visited_module_id" : module,
 }
*/

- (NSString*)getFormattedDate {
    NSDate* date = [NSDate date];
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSSSSSZ"];
    NSString* strdate = [format stringFromDate:date];

    NSString* substringFirst = [strdate substringToIndex:29];
    NSString* substringsecond = [strdate substringFromIndex:29];
    strdate = [NSString stringWithFormat:@"%@:%@", substringFirst, substringsecond];
    return strdate;
}

- (void)updateLastVisitedModule:(NSString*)module forCourseID:(NSString*)courseID {
    if(!module) {
        return;
    }

    NSString* timestamp = [self getFormattedDate];

    // Set to DB first and then depending on the response the DB gets updated
    [self setLastAccessedDataToDB:module withTimeStamp:timestamp forCourseID:courseID];

    NSString* path = [NSString stringWithFormat:@"/api/mobile/v0.5/users/%@/course_status_info/%@", [OEXSession sharedSession].currentUser.username, courseID];

    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, path]]];

    [request setHTTPMethod:@"PATCH"];
    NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    NSDictionary* dictionary = @{
        @"modification_date" : timestamp,
        @"last_visited_module_id" : module
    };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];

    [[session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            NSDictionary* dict = [NSJSONSerialization oex_JSONObjectWithData:data error:&error];

            NSArray* visitedPath = [dict objectForKey:@"last_visited_module_path"];

            NSString* subsectionID;

            for(NSString * subs in visitedPath) {
                if([subs rangeOfString:@"sequential"].location != NSNotFound) {
                    subsectionID = [visitedPath objectAtIndex:2];
                    break;
                }
            }

            if(![module isEqualToString:subsectionID]) {
                [self setLastAccessedDataToDB:subsectionID withTimeStamp:timestamp forCourseID:courseID];
            }
        }] resume];
}

- (void)setLastAccessedDataToDB:(NSString*)subsectionID withTimeStamp:(NSString*)timestamp forCourseID:(NSString*)courseID {
    OEXHelperVideoDownload* video = [self getSubsectionNameForSubsectionID:subsectionID];
    [self setLastAccessedSubSectionWithIDWithSubsectionID:subsectionID subsectionName: video.summary.sectionPathEntry.entryID courseID:courseID timeStamp:timestamp];
}

- (void)getLastVisitedModuleForCourseID:(NSString*)courseID {
    NSString* path = [NSString stringWithFormat:@"/api/mobile/v0.5/users/%@/course_status_info/%@",
                      [OEXSession sharedSession].currentUser.username, courseID];

    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, path]]];

    [request setHTTPMethod:@"GET"];
    NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];

    [[session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            NSDictionary* dict = [NSJSONSerialization oex_JSONObjectWithData:data error:&error];

            NSArray* visitedPath = [dict objectForKey:@"last_visited_module_path"];

            NSString* subsectionID;

            for(NSString * subs in visitedPath) {
                if([subs rangeOfString:@"sequential"].location != NSNotFound) {
                    subsectionID = subs;
                    break;
                }
            }

            if(subsectionID) {
                NSString* timestamp = [self getFormattedDate];
                // Set to DB first and then depending on the response the DB gets updated
                [self setLastAccessedDataToDB:subsectionID withTimeStamp:timestamp forCourseID:courseID];

                //Post notification
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                                    object:self
                                                                  userInfo:@{NOTIFICATION_KEY_URL: NOTIFICATION_VALUE_URL_LASTACCESSED,
                                                                             NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_SUCCESS}];
            }
        }] resume];
}

#pragma mark - Analytics Call

- (void)sendAnalyticsEvents:(OEXVideoState)state withCurrentTime:(NSTimeInterval)currentTime forVideo:(OEXHelperVideoDownload*)video {
    if(isnan(currentTime)) {
        currentTime = 0;
    }
    OEXLogInfo(@"VIDEO", @"Sending analytics");

    switch(state)
    {
        case OEXVideoStateLoading:
            if(video.summary.videoID) {
                [[OEXAnalytics sharedAnalytics] trackVideoLoading:video.summary.videoID
                                                         CourseID:video.course_id
                                                          UnitURL:video.summary.unitURL];
            }

            break;

        case OEXVideoStateStop:
            if(video.summary.videoID) {
                [[OEXAnalytics sharedAnalytics] trackVideoStop:video.summary.videoID
                                                   CurrentTime:currentTime
                                                      CourseID:video.course_id
                                                       UnitURL:video.summary.unitURL];
            }

            break;

        case OEXVideoStatePlay:
            if(video.summary.videoID) {
                [[OEXAnalytics sharedAnalytics] trackVideoPlaying:video.summary.videoID
                                                      CurrentTime:currentTime
                                                         CourseID:video.course_id
                                                          UnitURL:video.summary.unitURL];
            }

            break;

        case OEXVideoStatePause:
            if(video.summary.videoID) {
                // MOB - 395
                [[OEXAnalytics sharedAnalytics] trackVideoPause:video.summary.videoID
                                                    CurrentTime:currentTime
                                                       CourseID:video.course_id
                                                        UnitURL:video.summary.unitURL];
            }

            break;

        default:
            break;
    }
}

#pragma mark deactivate user interface
- (void)deactivate {
    
    // Set the language to blank
    [OEXInterface setCCSelectedLanguage:@""];
    
    if(!_network) {
        return;
    }
    [self.network invalidateNetworkManager];
    self.network = nil;
    [_downloadManger deactivateWithCompletionHandler:^{
        [_storage deactivate];
        self.parser = nil;
        self.numberOfRecentDownloads = 0;
    }];
}

# pragma  mark activate interface for user

- (void)activateInterfaceForUser:(OEXUserDetails*)user {
    [_network invalidateNetworkManager];
    
    // Reset Default Settings
    self.storage = [OEXStorageFactory getInstance];
    self.network = [[OEXNetworkInterface alloc] init];
    self.downloadManger = [OEXDownloadManager sharedManager];
    self.parser = [[OEXDataParser alloc] init];
    self.downloadManger.delegate = self;
    self.network.delegate = self;
    self.commonDownloadProgress = -1;
    // Used for CC
    _sharedInterface.selectedCCIndex = -1;
    _sharedInterface.selectedVideoSpeedIndex = -1;
    self.courseVideos = [[NSMutableDictionary alloc] init];

    NSString* key = [NSString stringWithFormat:@"%@_numberOfRecentDownloads", user.username];
    NSInteger recentDownloads = [[NSUserDefaults standardUserDefaults] integerForKey:key];
    //Downloads
    self.numberOfRecentDownloads = (int)recentDownloads;

    [[OEXDownloadManager sharedManager] activateDownloadManager];
    [self backgroundInit];

    //timed function
    if([_timer isValid]) {
        [_timer invalidate];
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                              target:self
                                            selector:@selector(updateTotalProgress)
                                            userInfo:nil
                                             repeats:YES];
    [_timer fire];
    [self startAllBackgroundDownloads];
}

#pragma mark - Course Enrollments
- (UserCourseEnrollment*)enrollmentForCourseWithID:(NSString*)courseID {
    for (UserCourseEnrollment* enrollment in self.courses) {
        if([enrollment.course.course_id isEqualToString:courseID]) {
            return enrollment;
        }
    }
    return nil;
}

#pragma mark - App Version

- (void) saveAppVersion {
    [[NSUserDefaults standardUserDefaults] setObject:[NSBundle mainBundle].oex_buildVersionString forKey:OEXSavedAppVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (nullable NSString*) getSavedAppVersion {
    return [[NSUserDefaults standardUserDefaults] objectForKey:OEXSavedAppVersionKey];
}

@end
