//
//  EdXInterface.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXInterface.h"

#import "NSArray+OEXSafeAccess.h"
#import "NSString+OEXFormatting.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXHelperVideoDownload.h"
#import "OEXDataParser.h"
#import "OEXDownloadManager.h"
#import "OEXNetworkConstants.h"
#import "OEXStorageFactory.h"
#import "OEXTranscriptsData.h"
#import "OEXUserDetails.h"
#import "OEXUserCourseEnrollment.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"
#import "Reachability.h"
#import "VideoData.h"

@interface OEXInterface () <OEXDownloadManagerProtocol>

@property (nonatomic, strong) OEXNetworkInterface* network;
@property (nonatomic, weak) id <OEXStorageInterface>  storage;
@property (nonatomic, strong) OEXDataParser* parser;
@property(nonatomic, weak) OEXDownloadManager* downloadManger;

/// Maps String (representing course video outline) -> OEXVideoSummary array
@property (nonatomic, strong) NSMutableDictionary* videoSummaries;

//Cached Data
@property (nonatomic, assign) int commonDownloadProgress;

@property (nonatomic, strong) NSArray* multipleDownloadArray;

@property(nonatomic, strong) NSTimer* timer;

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
    self.videoSummaries = [[NSMutableDictionary alloc] init];

	//Listen to download notification
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(downloadCompleteNotification:)
     name:DL_COMPLETE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(videoDownloadComplete:)
     name:VIDEO_DL_COMPLETE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressNotification:) name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];

    [self firstLaunchWifiSetting];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)backgroundInit {
	//User data
    self.userdetail = [OEXAuthentication getLoggedInUser];
	//course details
    self.courses = [self parsedObjectWithData:[self resourceDataForURLString:[_network URLStringForType:URL_COURSE_ENROLLMENTS] downloadIfNotAvailable:NO] forURLString:[_network URLStringForType:URL_COURSE_ENROLLMENTS]];

	//videos
    for(OEXUserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;
	//course subsection
        NSString* courseVideoDetails = course.video_outline;
        NSArray* array = [self videosOfCourseWithURLString:courseVideoDetails];
        [self storeVideoList:array forURL:courseVideoDetails];
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         [self resumePausedDownloads];
     }];
}

#pragma mark common methods

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
    else if([URLString rangeOfString:URL_VIDEO_SUMMARY].location != NSNotFound) {
        return [self processVideoSummaryList:data URLString:URLString];
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
    NSMutableString* URLString = [NSMutableString stringWithString:[OEXConfig sharedConfig].apiHostURL];

    if([type isEqualToString:URL_USER_DETAILS]) {
        [URLString appendFormat:@"%@/%@", URL_USER_DETAILS, [[OEXInterface sharedInterface] signInUserName]];
    }
    else if([type isEqualToString:URL_COURSE_ENROLLMENTS]) {
        [URLString appendFormat:@"%@/%@%@", URL_USER_DETAILS, [[OEXInterface sharedInterface] signInUserName], URL_COURSE_ENROLLMENTS];
    }
    else {
        return nil;
    }
	//Append tail
    [URLString appendString:@"?format=json"];

    return URLString;
}

+ (BOOL)isURLForVideo:(NSString*)URLString {
	//    https://d2f1egay8yehza.cloudfront.net/mit-6002x/MIT6002XT214-V043800_MB2.mp4
    if([URLString rangeOfString:URL_SUBSTRING_VIDEOS].location != NSNotFound) {
        return YES;
    }
    else if([URLString rangeOfString:URL_EXTENSION_VIDEOS].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (BOOL)isURLForedXDomain:(NSString*)URLString {
    if([URLString rangeOfString:[OEXConfig sharedConfig].apiHostURL].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (BOOL)isURLForImage:(NSString*)URLString {
    if([URLString rangeOfString:URL_SUBSTRING_ASSETS].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (BOOL)isURLForVideoOutline:(NSString*)URLString {
    if([URLString rangeOfString:URL_VIDEO_SUMMARY].location != NSNotFound) {
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

+ (void)setDownloadOnlyOnWifiPref:(BOOL)should {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:should forKey:USERDEFAULT_KEY_WIFIONLY];
    [userDefaults synchronize];
}

#pragma mark public methods
-(void)setNumberOfRecentDownloads:(int)numberOfRecentDownloads {
    _numberOfRecentDownloads = numberOfRecentDownloads;
    if([OEXAuthentication getLoggedInUser].username) {
        OEXUserDetails* user = [OEXAuthentication getLoggedInUser];
        NSString* key = [NSString stringWithFormat:@"%@_numberOfRecentDownloads", user.username];
        [[NSUserDefaults standardUserDefaults] setInteger:_numberOfRecentDownloads forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)loggedInUser:(OEXUserDetails*)user {
    self.userdetail = user;
    self.signInUserName = user.username;
    self.signInID = user.email;
}

#pragma mark - Persist the CC selected Language

+ (void)setCCSelectedLanguage:(NSString*)language {
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:PERSIST_CC];
}

+ (NSString*)getCCSelectedLanguage {
    return [[NSUserDefaults standardUserDefaults] objectForKey:PERSIST_CC];
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
    else if([URLString rangeOfString:URL_VIDEO_SRT_FILE].location != NSNotFound) {	// For Closed Captioning
        [_network downloadWithURLString:URLString];
    }
    else if([OEXInterface isURLForImage:URLString]) {
        return NO;
    }

    NSString* filePath = [OEXFileUtility completeFilePathForUrl:URLString];

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

- (NSInteger)downloadMultipleVideosForRequestStrings:(NSArray*)array {
    double totalSpaceRequired = 0;
	//Total space
    for(OEXHelperVideoDownload* video in array) {
        totalSpaceRequired += [video.summary.size doubleValue];
    }
    totalSpaceRequired = totalSpaceRequired / 1024 / 1024 / 1024;
    OEXAppDelegate* appD = [[UIApplication sharedApplication] delegate];
    if([OEXInterface shouldDownloadOnlyOnWifi]) {
        if(![appD.reachability isReachableViaWiFi]) {
            return 0;
        }
    }

    if(totalSpaceRequired > 1) {
        self.multipleDownloadArray = array;

	// As suggested by Lou
        UIAlertView* alertView =
            [[UIAlertView alloc] initWithTitle: OEXLocalizedString([@"LARGE_DOWNLOAD_TITLE" oex_uppercaseStringInCurrentLocale], nil)
             message:OEXLocalizedString(@"LARGE_DOWNLOAD_MESSAGE", nil)
             delegate:self
             cancelButtonTitle:[OEXLocalizedString(@"CANCEL", nil) oex_uppercaseStringInCurrentLocale]
             otherButtonTitles:[OEXLocalizedString(@"ACCEPT_LARGE_VIDEO_DOWNLOAD", nil) oex_uppercaseStringInCurrentLocale], nil];

        [alertView show];
        return 0;
    }

    return [self doDownloadMultipleVideosForRequestStrings:array];
}

- (NSInteger)doDownloadMultipleVideosForRequestStrings:(NSArray*)array {
    NSInteger count = 0;
    for(OEXHelperVideoDownload* video in array) {
        if(video.summary.videoURL.length > 0) {
            [self downloadBulkTranscripts:video];
            [self addVideoForDownload:video completionHandler:^(BOOL success){
             }];
            count++;
        }
    }
    return count;
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

-(float)lastPlayedIntervalForVideoID:(NSString*)videoID {
    return [_storage lastPlayedIntervalForVideoID:videoID];
}

- (void)markLastPlayedInterval:(float)playedInterval forVideoID:(NSString*)videoId {
    if(playedInterval <= 0) {
        return;
    }
    [_storage markLastPlayedInterval:playedInterval forVideoID:videoId];
}

- (void)deleteDownloadedVideoForVideoId:(NSString*)videoId completionHandler:(void (^)(BOOL success))completionHandler {
    [_storage deleteDataForVideoID:videoId];
    completionHandler(YES);
}

- (void)setAllEntriesUnregister {
    [_storage unregisterAllEntries];
}

-(void)setRegisteredCourses:(NSMutableSet*)courses {
    NSArray* videos = [self.storage getAllLocalVideoData];
    for(VideoData* video in videos) {
        if([courses containsObject:video.enrollment_id]) {
            video.is_registered = [NSNumber numberWithBool:YES];
        }
    }
    [self.storage saveCurrentStateToDB];
}

-(void)deleteUnregisteredItems {
    [_storage deleteUnregisteredItems];
}

- (VideoData*)insertVideoData:(OEXHelperVideoDownload*)helperVideo {
    return [_storage insertVideoData: @""
            Title: helperVideo.summary.name
            Size: [NSString stringWithFormat:@"%.2f", [helperVideo.summary.size doubleValue]]
            Durartion: [NSString stringWithFormat:@"%.2f", helperVideo.summary.duration]
            FilePath: [OEXFileUtility userRelativePathForUrl:helperVideo.summary.videoURL]
            OEXDownloadState: helperVideo.state
            VideoURL: helperVideo.summary.videoURL
            VideoID: helperVideo.summary.videoID
            UnitURL: helperVideo.summary.unitURL
            CourseID: helperVideo.course_id
            DMID: 0
            ChapterName: helperVideo.summary.chapterPathEntry.name
            SectionName: helperVideo.summary.sectionPathEntry.name
            TimeStamp: nil
            LastPlayedTime: helperVideo.lastPlayedInterval
            is_Reg: YES
            OEXPlayedState: helperVideo.watchedState];
}

#pragma mark Last Accessed

- (void)setLastAccessedSubsectionWith:(NSString*)subsectionID andSubsectionName:(NSString*)subsectionName forCourseID:(NSString*)courseID OnTimeStamp:(NSString*)timestamp {
    [_storage setLastAccessedSubsection:subsectionID andSubsectionName:subsectionName forCourseID:courseID OnTimeStamp:timestamp];
}

- (OEXHelperVideoDownload*)lastAccessedSubsectionForCourseID:(NSString*)courseID {
    LastAccessed* lastAccessed = [_storage lastAccessedDataForCourseID:courseID];

    if(lastAccessed.course_id) {
        for(OEXUserCourseEnrollment* courseEnrollment in _courses) {
            OEXCourse* course = courseEnrollment.course;

            if([courseID isEqualToString:course.course_id]) {
                for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
                    ELog(@"video.subSectionID : %@", video.summary.sectionPathEntry.entryID);
                    ELog(@"lastAccessed.subsection_id : %@ \n *********************\n", lastAccessed.subsection_id);

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
        total += 100;
        done += video.DownloadProgress;
    }

    BOOL viewHidden = YES;

    if(total > 0) {
        self.totalProgress = (float)done / (float)total;
        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TOTAL_DL_PROGRESS object:nil];
        }
	//show circular views
        viewHidden = NO;
    }
    else {
        viewHidden = YES;
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

-(void)videoDownloadComplete:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;
    NSURLSessionTask* task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL* url = task.originalRequest.URL;
    if([OEXInterface isURLForVideo:url.absoluteString]) {
        self.numberOfRecentDownloads++;
        [self markDownloadProgress:100 forURL:url.absoluteString andVideoId:nil];
    }
}

- (void)downloadProgressNotification:(NSNotification*)notification {
    NSDictionary* dictProgress = (NSDictionary*)notification.userInfo;

    NSURLSessionTask* task = [dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TASK];
    NSString* url = [task.originalRequest.URL absoluteString];
    double totalBytesWritten = [[dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN] doubleValue];
    double totalBytesExpectedToWrite = [[dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE] doubleValue];

    double completed = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    float completedPercent = completed * 100;

    [self markDownloadProgress:completedPercent forURL:url andVideoId:nil];
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    Reachability* reachability = (Reachability*)[notification object];

    if([reachability isReachable]) {
        self.reachable = YES;
        self.shownOfflineView = NO;

	// TODO: Resume downloads on network availability
	// [self resumePausedDownloads];
    }
    else {
        self.reachable = NO;
        self.shownOfflineView = YES;
    }

    [self.progressViews makeObjectsPerformSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:!self.reachable]];
}

#pragma mark NetworkInterface Delegate
- (void)returnedData:(NSData*)data forType:(NSString*)URLString {
	//Update Storage
    [self updateWithData:data forRequestString:URLString];

	//Parse and return
    [self processData:data forType:URLString usingOfflineCache:NO];
}

- (void)returnedFaliureForType:(NSString*)URLString {
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
    for(OEXHelperVideoDownload* video in [self allVideos]) {
        if(([video.summary.videoURL isEqualToString:URLString] && video.state == OEXDownloadStatePartial)
           || [video.summary.videoID isEqualToString:videoId]) {
            video.DownloadProgress = progress;
            video.isVideoDownloading = YES;
            if(progress == 100) {
                video.state = OEXDownloadStateComplete;
                video.isVideoDownloading = NO;
                video.completedDate = [NSDate date];
            }
            else if(progress > 0) {
                video.state = OEXDownloadStatePartial;
            }
            else {
                video.state = OEXDownloadStateNew;
                video.isVideoDownloading = NO;
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

	//Take action based on object type
        if([URLString isEqualToString:[self URLStringForType:URL_USER_DETAILS]]) {
            self.userdetail = (OEXUserDetails*)object;
        }
	//download any additional data if required
        else if([URLString isEqualToString:[self URLStringForType:URL_COURSE_ENROLLMENTS]]) {
            self.courses = (NSArray*)object;
            for(OEXUserCourseEnrollment* courseEnrollment in _courses) {
                OEXCourse* course = courseEnrollment.course;

		//course enrolments, get images for background
                NSString* courseImage = course.course_image_url;
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
	//video outlines populate videos
        else if([OEXInterface isURLForVideoOutline:URLString]) {
            NSArray* array = [self videosOfCourseWithURLString:URLString];
            [self storeVideoList:array forURL:URLString];
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

- (void)storeVideoList:(NSArray*)videos forURL:(NSString*)URLString {
    OEXCourse* objCourse = [[OEXCourse alloc] init];

    for(OEXUserCourseEnrollment* courseEnroll in _courses) {
        OEXCourse* obj = courseEnroll.course;
        if([obj.video_outline isEqualToString:URLString]) {
            objCourse = obj;
            break;
        }
    }

	//Add to dict
    [_courseVideos setObject:videos forKey:URLString];
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

        video.course_id = objCourse.course_id;
        video.course_url = objCourse.video_outline;

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
                video.DownloadProgress = 1.0;
                partiallyDownloaded++;
                break;
            default:
                video.isVideoDownloading = YES;
                video.DownloadProgress = 100.0;
                video.completedDate = data.downloadCompleteDate;
                downloadCompleted++;
                break;
        }
        video.state = downloadState;
    }
}

- (NSMutableArray*)videosForChapterID:(NSString*)chapter
    sectionID:(NSString*)section
    URL:(NSString*)URLString {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : URLString]) {
        if([video.summary.chapterPathEntry.entryID isEqualToString:chapter]) {
            if(section) {
                if([video.summary.sectionPathEntry.entryID isEqualToString:section]) {
                    [array addObject:video];
                }
            }
            else {
                [array addObject:video];
            }
        }
    }
    return array;
}

- (NSMutableArray*)coursesAndVideosForDownloadState:(OEXDownloadState)state {
    NSMutableArray* mainArray = [[NSMutableArray alloc] init];

    for(OEXUserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;
	//Videos array
        NSMutableArray* videosArray = [[NSMutableArray alloc] init];

        for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
		//Complete
            if(video.state == OEXDownloadStateComplete && state == OEXDownloadStateComplete) {
                [videosArray addObject:video];
            }
		//Partial
            else if(video.state == OEXDownloadStatePartial && video.DownloadProgress < 100 && state == OEXDownloadStatePartial) {
                [videosArray addObject:video];
            }
            else if(video.state == OEXDownloadStateNew && state == OEXDownloadStateNew) {
                [videosArray addObject:video];
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

    for(OEXUserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;

        for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
            [mainArray addObject:video];
        }
    }

    return mainArray;
}

- (OEXHelperVideoDownload*)getSubsectionNameForSubsectionID:(NSString*)subsectionID {
    for(OEXUserCourseEnrollment* courseEnrollment in _courses) {
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

    for(OEXUserCourseEnrollment* courseEnrollment in _courses) {
        OEXCourse* course = courseEnrollment.course;

        for(OEXHelperVideoDownload* video in [_courseVideos objectForKey : course.video_outline]) {
		//Complete
            if((video.DownloadProgress == 100) && (state == OEXDownloadStateComplete)) {
                [mainArray addObject:video];
            }
		//Partial
            else if((video.isVideoDownloading && (video.DownloadProgress < 100)) && (state == OEXDownloadStatePartial)) {
                [mainArray addObject:video];
            }
            else if(!video.isVideoDownloading && (state == OEXDownloadStateNew)) {
                [mainArray addObject:video];
            }
        }
    }

    return mainArray;
}
- (NSArray*)sectionsForChapterID:(NSString*)chapterID URLString:(NSString*)URL {
	// To get the sections for the given chapter name
    NSMutableArray* sectionEntries = [[NSMutableArray alloc] init];

    for(OEXVideoSummary* objVideo in [self.videoSummaries objectForKey : URL]) {
        OEXVideoPathEntry* chapterEntry = objVideo.chapterPathEntry;
        if([chapterEntry.entryID isEqualToString:chapterID]) {
            OEXVideoPathEntry* sectionEntry = objVideo.sectionPathEntry;
            if(![sectionEntries containsObject:sectionEntry]) {
                [sectionEntries addObject: sectionEntry];
            }
        }
    }

    return sectionEntries;
}

- (NSDictionary*)processVideoSummaryList:(NSData*)data URLString:(NSString*)URLString {
    [self.videoSummaries removeObjectForKey:URLString];
    NSArray* summaries = [self.parser videoSummaryListWithData:data];
    [self.videoSummaries setObject:summaries forKey:URLString];
    return self.videoSummaries;
}

- (NSArray*)videosOfCourseWithURLString:(NSString*)URL {
	// Get the data from the URL
    NSData* data = [self resourceDataForURLString:URL downloadIfNotAvailable:NO];
    if(data) {
        [self processVideoSummaryList:data URLString:URL];
    }
    else {
        [self downloadWithRequestString:URL forceUpdate:YES];
    }

	// Return this array of course video objects.
    NSMutableArray* arr_Videos = [[NSMutableArray alloc] init];

    for(OEXVideoSummary* objVideo in [self.videoSummaries objectForKey : URL]) {
        OEXHelperVideoDownload* obj_helperVideo = [[OEXHelperVideoDownload alloc] init];
        obj_helperVideo.summary = objVideo;
        obj_helperVideo.filePath = [OEXFileUtility completeFilePathForUrl:obj_helperVideo.summary.videoURL];

        [arr_Videos addObject:obj_helperVideo];
    }

    return arr_Videos;
}

- (NSString*)openInBrowserLinkForCourse:(OEXCourse*)course {
    NSString* str_link = [[NSString alloc] init];
    for(OEXVideoSummary* objVideo in [self.videoSummaries objectForKey : course.video_outline]) {
        str_link = objVideo.sectionURL;
    }

    return str_link;
}

- (NSArray*)chaptersForURLString:(NSString*)URL {
	// To get all the chapter data
    NSMutableArray* chapterEntries = [[NSMutableArray alloc] init];

    for(OEXVideoSummary* objVideo in [self.videoSummaries objectForKey : URL]) {
        OEXVideoPathEntry* chapterPathEntry = objVideo.chapterPathEntry;
        if(![chapterEntries containsObject:chapterPathEntry]) {
            [chapterEntries oex_safeAddObject: chapterPathEntry];
        }
    }

    return chapterEntries;
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        NSInteger count = [self doDownloadMultipleVideosForRequestStrings:_multipleDownloadArray];
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

#pragma mark - Bulk Download
- (float)showBulkProgressViewForCourse:(OEXCourse*)course chapterID:(NSString*)chapterID sectionID:(NSString*)sectionID {
    NSMutableArray* arr_Videos = [self videosForChapterID:chapterID sectionID:sectionID URL:course.video_outline];

    float total = 0;
    float done = 0;
    float totalProgress = -1;
    NSInteger count = 0;

    for(OEXHelperVideoDownload* objvideo in arr_Videos) {
        if(objvideo.state == OEXDownloadStateNew) {
            return -1;
        }
        else if(objvideo.state == OEXDownloadStatePartial) {
            total += 100;
            done += objvideo.DownloadProgress;
            totalProgress = (float)done / (float)total;
        }
        else {
            count++;
            if(count == [arr_Videos count]) {
                return -1;
            }
        }
    }

    return totalProgress;
}

#pragma mark - SRT bulk download
- (void)downloadBulkTranscripts:(OEXHelperVideoDownload*)obj;
{
	// Download Chinese
    if(obj.summary.srtChinese) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtChinese downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtChinese forceUpdate:YES];
        }
    }

	// Download English
    if(obj.summary.srtEnglish) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtEnglish downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtEnglish forceUpdate:YES];
        }
    }

	// Download German
    if(obj.summary.srtGerman) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtGerman downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtGerman forceUpdate:YES];
        }
    }

	// Download Portuguese
    if(obj.summary.srtPortuguese) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtPortuguese downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtPortuguese forceUpdate:YES];
        }
    }

	// Download Spanish
    if(obj.summary.srtSpanish) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtSpanish downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtSpanish forceUpdate:YES];
        }
    }
}

#pragma mark - Download Video

-(void)startDownloadForVideo:(OEXHelperVideoDownload*)video completionHandler:(void (^)(BOOL sucess))completionHandler {
    OEXAppDelegate* appD = [[UIApplication sharedApplication] delegate];
    if([OEXInterface isURLForVideo:video.summary.videoURL]) {
        if([OEXInterface shouldDownloadOnlyOnWifi]) {
            if(![appD.reachability isReachableViaWiFi]) {
                completionHandler(NO);
                return;
            }
        }
    }
    [self addVideoForDownload:video completionHandler:completionHandler];
}

-(void)addVideoForDownload:(OEXHelperVideoDownload*)video completionHandler:(void (^)(BOOL sucess))completionHandler {
    __block VideoData* data = [_storage videoDataForVideoID:video.summary.videoID];
    if(!data || !data.video_url) {
        data = [self insertVideoData:video];
    }

    NSArray* array = [_storage getVideosForDownloadUrl:video.summary.videoURL];
    if([array count] > 1) {
        for(VideoData* videoObj in array) {
            if([videoObj.download_state intValue] == OEXDownloadStateComplete) {
                [_storage completedDownloadForVideo:data];
                video.DownloadProgress = 100;
                video.isVideoDownloading = NO;
                video.state = OEXDownloadStateComplete;
                completionHandler(YES);
                return;
            }
        }
    }

    if(data) {
        [[OEXDownloadManager sharedManager] downloadVideoForObject:data withCompletionHandler:^(NSURLSessionDownloadTask* downloadTask) {
             if(downloadTask) {
                 video.state = OEXDownloadStatePartial;
                 video.DownloadProgress = 0.1;
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
-(void)cancelDownloadForVideo:(OEXHelperVideoDownload*)video completionHandler:(void (^) (BOOL))completionHandler {
    VideoData* data = [_storage videoDataForVideoID:video.summary.videoID];

    if(data) {
        [[OEXDownloadManager sharedManager] cancelDownloadForVideo:data completionHandler:^(BOOL success) {
             video.state = OEXDownloadStateNew;
             video.DownloadProgress = 0;
             video.isVideoDownloading = NO;
             completionHandler(success);
         }];
    }
    else {
        video.isVideoDownloading = NO;
        video.DownloadProgress = 0;
        video.state = OEXDownloadStateNew;
    }
}

- (void)resumePausedDownloads {
    [_downloadManger resumePausedDownloads];
}

#pragma mark Video Management

-(OEXDownloadState)stateForVideo:(OEXHelperVideoDownload*)video {
    return [self.storage videoStateForVideoID:video.summary.videoID];
}
-(OEXPlayedState)watchedStateForVideo:(OEXHelperVideoDownload*)video {
    return [self.storage watchedStateForVideoID:video.summary.videoID];
}

- (float)lastPlayedIntervalForVideo:(OEXHelperVideoDownload*)video {
    return [_storage lastPlayedIntervalForVideoID:video.summary.videoID];
}

- (void)markVideoState:(OEXPlayedState)state forVideo:(OEXHelperVideoDownload*)video {
    if(video.summary.videoID) {
        [self.storage markPlayedState:state forVideoID:video.summary.videoID];
    }
}

- (void)markDownloadState:(OEXDownloadState)state forVideo:(OEXHelperVideoDownload*)video {
    for(OEXHelperVideoDownload* videoObj in [self allVideos]) {
        if([videoObj.summary.videoID isEqualToString:video.summary.videoID]) {
            videoObj.state = state;
            if(state == OEXDownloadStateNew) {
                videoObj.isVideoDownloading = NO;
                videoObj.DownloadProgress = 0.0;
            }
        }
    }
}

- (void)markLastPlayedInterval:(float)playedInterval forVideo:(OEXHelperVideoDownload*)video {
    [_storage markLastPlayedInterval:playedInterval forVideoID:video.summary.videoID];
}
#pragma mark - Closed Captioning
- (void)downloadTranscripts:(OEXHelperVideoDownload*)obj;
{
    OEXTranscriptsData* obj_Transcripts = [[OEXTranscriptsData alloc] init];
    obj_Transcripts.ChineseDownloadURLString = obj.summary.srtChinese;
    obj_Transcripts.EnglishDownloadURLString = obj.summary.srtEnglish;
    obj_Transcripts.GermanDownloadURLString = obj.summary.srtGerman;
    obj_Transcripts.PortugueseDownloadURLString = obj.summary.srtPortuguese;
    obj_Transcripts.SpanishDownloadURLString = obj.summary.srtSpanish;
    obj_Transcripts.FrenchDownloadURLString = obj.summary.srtFrench;

	// Download Chinese
    if(obj.summary.srtChinese) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtChinese downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtChinese forceUpdate:YES];
        }

        obj_Transcripts.ChineseURLFilePath = [OEXFileUtility completeFilePathForUrl:obj.summary.srtChinese];
    }

	// Download English
    if(obj.summary.srtEnglish) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtEnglish downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtEnglish forceUpdate:YES];
        }

        obj_Transcripts.EnglishURLFilePath = [OEXFileUtility completeFilePathForUrl:obj.summary.srtEnglish];
    }

	// Download German
    if(obj.summary.srtGerman) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtGerman downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtGerman forceUpdate:YES];
        }

        obj_Transcripts.GermanURLFilePath = [OEXFileUtility completeFilePathForUrl:obj.summary.srtGerman];
    }

	// Download Portuguese
    if(obj.summary.srtPortuguese) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtPortuguese downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtPortuguese forceUpdate:YES];
        }

        obj_Transcripts.PortugueseURLFilePath = [OEXFileUtility completeFilePathForUrl:obj.summary.srtPortuguese];
    }

	// Download Spanish
    if(obj.summary.srtSpanish) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtSpanish downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtSpanish forceUpdate:YES];
        }

        obj_Transcripts.SpanishURLFilePath = [OEXFileUtility completeFilePathForUrl:obj.summary.srtSpanish];
    }

	// Download French
    if(obj.summary.srtFrench) {
        NSData* data = [self resourceDataForURLString:obj.summary.srtFrench downloadIfNotAvailable:NO];
        if(!data) {
            [self downloadWithRequestString:obj.summary.srtFrench forceUpdate:YES];
        }

        obj_Transcripts.FrenchURLFilePath = [OEXFileUtility completeFilePathForUrl:obj.summary.srtFrench];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TRANSCRIPT object:self userInfo:@{KEY_TRANSCRIPT: obj_Transcripts}];
}

#pragma mark DownloadManagerDelegate

-(void)downloadTaskDidComplete:(NSURLSessionDownloadTask*)task {
}

-(void)downloadTask:(NSURLSessionDownloadTask*)task didCOmpleteWithError:(NSError*)error {
    NSArray* array = [_storage videosForTaskIdentifier:task.taskIdentifier];
    for(VideoData* video in array) {
        video.dm_id = [NSNumber numberWithInt:0];
        video.download_state = [NSNumber numberWithInt:OEXDownloadStateNew];
    }
    [self markDownloadProgress:0.0 forURL:[task.originalRequest.URL absoluteString] andVideoId:nil];

    [_storage saveCurrentStateToDB];
}

-(void)downloadAlreadyInProgress:(NSURLSessionDownloadTask*)task {
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
    NSString* strdate = [[NSString alloc] init];
    strdate = [format stringFromDate:date];

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

    OEXUserDetails* user = [OEXAuthentication getLoggedInUser];

    NSString* path = [NSString stringWithFormat:@"/api/mobile/v0.5/users/%@/course_status_info/%@", user.username, courseID];

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

    [self setLastAccessedSubsectionWith:subsectionID andSubsectionName:video.summary.sectionPathEntry.entryID forCourseID:courseID OnTimeStamp:timestamp];
}

- (void)getLastVisitedModuleForCourseID:(NSString*)courseID {
    OEXUserDetails* user = [OEXAuthentication getLoggedInUser];

    NSString* path = [NSString stringWithFormat:@"/api/mobile/v0.5/users/%@/course_status_info/%@", user.username, courseID];

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

    switch(state)
    {
        case OEXVideoStateLoading:

            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStateStopped");

            if(video.summary.videoID) {
                [[OEXAnalytics sharedAnalytics] trackVideoLoading:video.summary.videoID
                 CourseID:video.course_id
                 UnitURL:video.summary.unitURL];
            }

            break;

        case OEXVideoStateStop:

            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStateStopped");

            if(video.summary.videoID) {
                [[OEXAnalytics sharedAnalytics] trackVideoStop:video.summary.videoID
                 CurrentTime:currentTime
                 CourseID:video.course_id
                 UnitURL:video.summary.unitURL];
            }

            break;

        case OEXVideoStatePlay:

            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStatePlaying");

            if(video.summary.videoID) {
                [[OEXAnalytics sharedAnalytics] trackVideoPlaying:video.summary.videoID
                 CurrentTime:currentTime
                 CourseID:video.course_id
                 UnitURL:video.summary.unitURL];
            }

            break;

        case OEXVideoStatePause:

            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStatePaused");
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
- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler {
    ELog(@"deactivateWithCompletionHandler -1");
    if(!_network) {
        completionHandler();
        return;
    }
    [self.network invalidateNetworkManager];
    self.network = nil;
    [_downloadManger deactivateWithCompletionHandler:^{
         [_storage deactivate];
         [OEXAuthentication clearUserSession];
         self.userdetail = nil;
         self.courses = nil;
         self.courseVideos = nil;
         self.signInID = nil;
         self.signInUserName = nil;
         self.signInPassword = nil;
         self.parser = nil;
         self.numberOfRecentDownloads = 0;
         [self.videoSummaries removeAllObjects];
         completionHandler();
     }];
}

# pragma  mark activate interface for user

-(void)activateInterfaceForUser:(OEXUserDetails*)user {
	// Reset Default Settings
    [OEXFileUtility userDirectory];
    [self loggedInUser:[OEXAuthentication getLoggedInUser]];
    self.storage = [OEXStorageFactory getInstance];
    self.network = [[OEXNetworkInterface alloc] init];
    self.downloadManger = [OEXDownloadManager sharedManager];
    self.parser = [[OEXDataParser alloc] init];
    self.downloadManger.delegate = self;
    self.network.delegate = self;
    self.commonDownloadProgress = -1;
    _sharedInterface.shownOfflineView = NO;
	// Used for CC
    _sharedInterface.selectedCCIndex = -1;
    _sharedInterface.selectedVideoSpeedIndex = -1;
    self.courseVideos = [[NSMutableDictionary alloc] init];

    NSString* key = [NSString stringWithFormat:@"%@_numberOfRecentDownloads", user.username];
    NSInteger recentDownloads = [[NSUserDefaults standardUserDefaults] integerForKey:key];
	//Downloads
    self.numberOfRecentDownloads = (int)recentDownloads;

    [_network activate];
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
}

@end
