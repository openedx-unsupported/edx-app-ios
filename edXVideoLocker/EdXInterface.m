//
//  EdXInterface.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "EdXInterface.h"

#import "AppDelegate.h"
#import "Course.h"
#import "EdxAuthentication.h"
#import "EDXConfig.h"
#import "EDXEnvironment.h"
#import "HelperVideoDownload.h"
#import "DataParser.h"
#import "DownloadManager.h"
#import "Reachability.h"
#import "StorageFactory.h"
#import "UserDetails.h"
#import "UserCourseEnrollment.h"
#import "VideoData.h"
#import "TranscriptsData.h"

@interface EdXInterface ()<DownloadManagerProtocol>

@property (nonatomic, strong) edXNetworkInterface * network;
@property (nonatomic, weak) id<StorageInterface>  storage;
@property (nonatomic, strong) DataParser * parser;
@property(nonatomic,weak) DownloadManager *downloadManger;

//Cached Data
@property (nonatomic, assign) int commonDownloadProgress;

@property (nonatomic, strong) NSArray * multipleDownloadArray;

@property(nonatomic,strong) NSTimer *timer;

@end

static EdXInterface * _sharedInterface = nil;

@implementation EdXInterface

#pragma mark Initialization

- (id)init {
    return nil;
}

+ (id)sharedInterface {
    if (!_sharedInterface) {
        _sharedInterface = [[EdXInterface alloc] initCustom];
    
        [_sharedInterface initialization];
    }
    return _sharedInterface;
}

- (id)initCustom {
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
                                                 name:VIDEO_DL_COMPLETE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressNotification:) name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
   
    
    [self firstLaunchWifiSetting];
    return self;
}

- (void)begin {
  
    [self backgroundInit];
}

- (void)initialization
{
    
    self.storage = [StorageFactory getInstance];
    self.network = [[edXNetworkInterface alloc] init];
    self.downloadManger=[DownloadManager sharedManager];
    self.parser = [[DataParser alloc] initWithDataInterface:self];
    _network.delegate = self;
    self.commonDownloadProgress = -1;
  }

-(void)backgroundInit {
    NSOperationQueue *queue=[[NSOperationQueue alloc]init];
    [queue addOperationWithBlock:^{
        //User data
        NSString * URLString =  [_network URLStringForType:URL_USER_DETAILS];
        NSData * userDataTemp = [self resourceDataForURLString:URLString downloadIfNotAvailable:NO];
        self.userdetail = [_parser parsedObjectWithData:userDataTemp forURLString:URLString];
        //course details
        self.courses = [_parser parsedObjectWithData:[self resourceDataForURLString:[_network URLStringForType:URL_COURSE_ENROLLMENTS] downloadIfNotAvailable:NO] forURLString:[_network URLStringForType:URL_COURSE_ENROLLMENTS]];
        
        //videos
        for (UserCourseEnrollment * courseEnrollment in _courses) {
            Course * course = courseEnrollment.course;
            //course subsection
            NSString * courseVideoDetails = course.video_outline;
            NSArray * array = [_parser getVideosOfCourseWithURLString:courseVideoDetails];
            [self storeVideoList:array forURL:courseVideoDetails];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self resumePausedDownloads];
        }];
       
    }];
}

- (void)activate {
    
    
}

#pragma mark common methods

- (NSString *)URLStringForType:(NSString *)type {
    
    NSMutableString * URLString = [NSMutableString stringWithString:[EDXEnvironment shared].config.apiHostURL];
    
    if ([type isEqualToString:URL_USER_DETAILS])
    {
        [URLString appendFormat:@"%@/%@", URL_USER_DETAILS, [[EdXInterface sharedInterface] signInUserName]];
    }
    else if ([type isEqualToString:URL_COURSE_ENROLLMENTS]) {
        [URLString appendFormat:@"%@/%@%@", URL_USER_DETAILS, [[EdXInterface sharedInterface] signInUserName], URL_COURSE_ENROLLMENTS];
    }
    else {
        return nil;
    }
    //Append tail
    [URLString appendString:@"?format=json"];
    
    return URLString;
}

+ (BOOL)isURLForVideo:(NSString *)URLString
{
    //    https://d2f1egay8yehza.cloudfront.net/mit-6002x/MIT6002XT214-V043800_MB2.mp4
    if ([URLString rangeOfString:URL_SUBSTRING_VIDEOS].location != NSNotFound) {
        return YES ;
    }else if([URLString rangeOfString:URL_EXTENSION_VIDEOS].location != NSNotFound)
    {
        return YES ;
    }
    return NO;
}

+ (BOOL)isURLForedXDomain:(NSString *)URLString {
    if ([URLString rangeOfString:[EDXEnvironment shared].config.apiHostURL].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (BOOL)isURLForImage:(NSString *)URLString {
    if ([URLString rangeOfString:URL_SUBSTRING_ASSETS].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (BOOL)isURLForVideoOutline:(NSString *)URLString {
    if ([URLString rangeOfString:URL_VIDEO_SUMMARY].location != NSNotFound) {
        return YES;
    }
    return NO;
}

- (void)createDatabaseDirectory {
    [_storage createDatabaseDirectory];
}

#pragma mark Wifi Only

- (void)firstLaunchWifiSetting {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults objectForKey:USERDEFAULT_KEY_WIFIONLY]) {
        [userDefaults setBool:YES forKey:USERDEFAULT_KEY_WIFIONLY];
    }
}

+ (BOOL)shouldDownloadOnlyOnWifi {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL should = [userDefaults boolForKey:USERDEFAULT_KEY_WIFIONLY];
    return should;
}

+ (void)setDownloadOnlyOnWifiPref:(BOOL)should {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:should forKey:USERDEFAULT_KEY_WIFIONLY];
    [userDefaults synchronize];
}

#pragma mark public methods
-(void)setNumberOfRecentDownloads:(int)numberOfRecentDownloads {
    _numberOfRecentDownloads = numberOfRecentDownloads;
    if([EdxAuthentication getLoggedInUser].username){
        UserDetails *user=[EdxAuthentication getLoggedInUser];
    NSString *key=[NSString stringWithFormat:@"%@_numberOfRecentDownloads", user.username];
    [[NSUserDefaults standardUserDefaults] setInteger:_numberOfRecentDownloads forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)loggedInUser:(UserDetails *)user {
    self.userdetail=user;
    self.signInUserName=user.username;
    self.signInID=user.email;
    [self activate];
}


#pragma mark - Persist the CC selected Language

+ (void)setCCSelectedLanguage:(NSString *)language
{
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:PERSIST_CC];
}

+ (NSString *)getCCSelectedLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:PERSIST_CC];
}


#pragma common Network Calls

- (void)startAllBackgroundDownloads {
    //If entering common download mode
    if (_commonDownloadProgress == -1) {
        self.commonDownloadProgress = 0;
    }
    [self downloadNextItem];
}

- (void)downloadNextItem {
    
    switch (_commonDownloadProgress) {
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

- (void)requestWithRequestString:(NSString *)URLString {
    //Network Request
    [_network callRequestString:URLString];
}
// This method Start Downloads for resources
- (BOOL)downloadWithRequestString:(NSString *)URLString forceUpdate:(BOOL)update {
    if (!_reachable || [EdXInterface isURLForVideo:URLString]) {
        return NO;
    }
    
    if ([URLString isEqualToString:URL_USER_DETAILS]) {
        URLString = [_network URLStringForType:URL_USER_DETAILS];
    }
    else if ([URLString isEqualToString:URL_COURSE_ENROLLMENTS]) {
        URLString = [_network URLStringForType:URL_COURSE_ENROLLMENTS];
    }
    else if ([URLString rangeOfString:URL_VIDEO_SRT_FILE].location != NSNotFound) // For Closed Captioning
    {
        [_network downloadWithURLString:URLString];
    }
    
    NSString * filePath = [FileUtility completeFilePathForUrl:URLString];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
         [_network downloadWithURLString:URLString];
    }
    else{
        if (update) {
            //Network Request
            [_network downloadWithURLString:URLString];
        }else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                                object:self
                                                              userInfo:@{NOTIFICATION_KEY_URL: URLString,
                                                                         NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_SUCCESS,
                                                                         NOTIFICATION_KEY_OFFLINE: NOTIFICATION_VALUE_OFFLINE_NO,
                                                                         }];
        }
    }
    return YES;
}

- (NSInteger)downloadMultipleVideosForRequestStrings:(NSArray *)array
{
    double totalSpaceRequired = 0;
    //Total space
    for (HelperVideoDownload * video in array) {
        totalSpaceRequired += [video.size doubleValue];
    }
    totalSpaceRequired = totalSpaceRequired / 1024 / 1024 / 1024;
    AppDelegate *appD = [[UIApplication sharedApplication] delegate];
    if ([EdXInterface shouldDownloadOnlyOnWifi])
    {
        if (![appD.reachability isReachableViaWiFi])
        {
            return 0;
        }
    }
    
    
    if (totalSpaceRequired > 1)
    {
        self.multipleDownloadArray = array;
        
        // As suggested by Lou
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LARGE_DOWNLOAD_TITLE", nil)
                                                             message:NSLocalizedString(@"LARGE_DOWNLOAD_MESSAGE", nil)
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                   otherButtonTitles:NSLocalizedString(@"DOWNLOAD", nil), nil];
        
        [alertView show];
        return 0;
    }
    
    
    return [self doDownloadMultipleVideosForRequestStrings:array];
}

- (NSInteger)doDownloadMultipleVideosForRequestStrings:(NSArray *)array {
        NSInteger count=0;
    for (HelperVideoDownload * video in array) {
        if(video.str_VideoURL!=nil && ![video.str_VideoURL isEqualToString:@""]){
        [self downloadBulkTranscripts:video];
        [self addVideoForDownload:video completionHandler:^(BOOL success){
            
        }];
            count++;
        }
    }
    return count;
}

- (NSData *)resourceDataForURLString:(NSString *)URLString downloadIfNotAvailable:(BOOL)shouldDownload {
    
    NSData * data = [_storage dataForURLString:URLString];
    //If data is not downloaded, start download
    if (!data && shouldDownload) {
        [self downloadWithRequestString:URLString forceUpdate:NO];
    }
    return data;
    
}

- (float)lastPlayedIntervalForURL:(NSString *)URLString {
    return 0;
}

-(float)lastPlayedIntervalForVideoID:(NSString *)videoID {
    return [_storage lastPlayedIntervalForVideoID:videoID];
}


- (void)markLastPlayedInterval:(float)playedInterval forVideoID:(NSString *)videoId {
    if(playedInterval<=0)
        return;
    [_storage markLastPlayedInterval:playedInterval forVideoID:videoId];
}

- (void)cancelDownloadWithURL:(NSString *)URLString completionHandler:(void (^)(BOOL success))completionHandler {
    
    //Delete from DB and session
    [_network cancelDownloadForURL:URLString completionHandler:^(BOOL success) {
            completionHandler(success);
    }];
    
}

- (void)deleteDownloadedVideoForVideoId:(NSString *)videoId completionHandler:(void (^)(BOOL success))completionHandler {
    
    [_storage deleteDataForVideoID:videoId];
    completionHandler(YES);
    
}



- (void)setAllEntriesUnregister
{
    [_storage unregisterAllEntries];
}

- (void)setRegisterCourseForCourseID:(NSString *)courseid
{
    [_storage setRegisteredCoursesAndDeleteUnregisteredData:courseid];
}

-(void)deleteUnregisteredItems
{
    [_storage deleteUnregisteredItems];
}




- (VideoData *)insertVideoData:(HelperVideoDownload *)helperVideo
{
    return  [_storage insertVideoData: @""
                        Title: helperVideo.name
                         Size: [NSString stringWithFormat:@"%.2f", [helperVideo.size floatValue]]
                    Durartion: [NSString stringWithFormat:@"%.2f", helperVideo.duration]
                     FilePath: [FileUtility userRelativePathForUrl:helperVideo.str_VideoURL]
                DownloadState: helperVideo.state
                     VideoURL: helperVideo.str_VideoURL
                      VideoID: helperVideo.video_id
                      UnitURL: helperVideo.unit_url
                     CourseID: helperVideo.course_id
                         DMID: 0
                  ChapterName: helperVideo.ChapterName
                  SectionName: helperVideo.SectionName
                    TimeStamp: nil
               LastPlayedTime: helperVideo.lastPlayedInterval
                       is_Reg: YES
                  PlayedState: helperVideo.watchedState];
}


#pragma mark Last Accessed

- (void)setLastAccessedSubsectionWith:(NSString *)subsectionID andSubsectionName:(NSString *)subsectionName forCourseID:(NSString *)courseID OnTimeStamp:(NSString *)timestamp
{
    [_storage setLastAccessedSubsection:subsectionID andSubsectionName:subsectionName forCourseID:courseID OnTimeStamp:timestamp];
}


- (HelperVideoDownload *)lastAccessedSubsectionForCourseID:(NSString *)courseID
{
    
    LastAccessed * lastAccessed = [_storage lastAccessedDataForCourseID:courseID];

    if (lastAccessed.course_id)
    {
        for (UserCourseEnrollment * courseEnrollment in _courses)
        {
            Course * course = courseEnrollment.course;

            if ([courseID isEqualToString:course.course_id])
            {
                for (HelperVideoDownload * video in [_courseVideos objectForKey:course.video_outline])
                {
                    ELog(@"video.subSectionID : %@", video.subSectionID);
                    ELog(@"lastAccessed.subsection_id : %@ \n *********************\n", lastAccessed.subsection_id);
                    
                    if ([video.subSectionID isEqualToString:lastAccessed.subsection_id])
                    {
                        return video;
                    }
                }
            }
        }
    }
    
    return nil;
}


#pragma mark Update Storage

- (void)updateWithData:(NSData *)data
      forRequestString:(NSString *)URLString {
    [_storage updateData:data ForURLString:URLString];
}

#pragma mark EdxNetworkInterface Delegate

- (void)updateTotalProgress {
    
    NSArray * array = [self allVideosForState:DownloadStatePartial];
    float total = 0;
    float done = 0;
    for (HelperVideoDownload * video in array) {
        total += 100;
        done += video.DownloadProgress;
    }
    
    BOOL viewHidden = YES;
    
    if (total > 0) {
        self.totalProgress = (float)done / (float)total;
        if([[UIApplication sharedApplication] applicationState]==UIApplicationStateActive){
            [[NSNotificationCenter defaultCenter] postNotificationName:TOTAL_DL_PROGRESS object:nil];
        }
        //show circular views
        viewHidden = NO;
    }
    else
    {
        viewHidden = YES;
    }
    
    if (!_reachable && !viewHidden) {
        viewHidden = YES;
    }
    
    for (UIView * view in _progressViews) {
        view.hidden = viewHidden;
    }
}

#pragma mark notification methods

- (void)downloadCompleteNotification:(NSNotification *)notification
{
    NSDictionary * dict = notification.userInfo;
    
    NSURLSessionTask * task = [dict objectForKey:DL_COMPLETE_N_TASK];
    NSURL * url = task.originalRequest.URL;

    NSData * data = [self resourceDataForURLString:url.absoluteString downloadIfNotAvailable:NO];
    [self returnedData:data forType:url.absoluteString];
}

-(void)videoDownloadComplete:(NSNotification *)notification{
    NSDictionary * dict = notification.userInfo;
    NSURLSessionTask * task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL * url = task.originalRequest.URL;
    if ([EdXInterface isURLForVideo:url.absoluteString]) {
        self.numberOfRecentDownloads++;
        [self markDownloadProgress:100 forURL:url.absoluteString andVideoId:nil];
    }
}


- (void)downloadProgressNotification:(NSNotification *)notification {
    NSDictionary *dictProgress = (NSDictionary *)notification.userInfo;
    
    NSURLSessionTask * task = [dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TASK];
    NSString *url = [task.originalRequest.URL absoluteString];
    double totalBytesWritten = [[dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN] doubleValue];
    double totalBytesExpectedToWrite = [[dictProgress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE] doubleValue];
    
    double completed = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    float completedPercent = completed * 100;
    
    [self markDownloadProgress:completedPercent forURL:url andVideoId:nil];
}


- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable]) {
        self.reachable = YES;
        self.shownOfflineView=NO;

#warning - TODO: Resume downloads on network availability
        // [self resumePausedDownloads];
        
    } else {
        self.reachable = NO;
        self.shownOfflineView=YES;
    }
    
    [self.progressViews makeObjectsPerformSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:!self.reachable]];
    
}




#pragma mark NetworkInterface Delegate
- (void)returnedData:(NSData *)data forType:(NSString *)URLString {
    
    //Update Storage
    [self updateWithData:data forRequestString:URLString];
    
    //Parse and return
    [self processData:data forType:URLString usingOfflineCache:NO];
}

- (void)returnedFaliureForType:(NSString *)URLString {
    
    //VIDEO URL
    if ([EdXInterface isURLForVideo:URLString]) {
        
    }
    else {
        
        //look for cached response
        NSData * data = [_storage dataForURLString:URLString];
        if (data) {
            [self processData:data forType:URLString usingOfflineCache:YES];
        }
        else
        {
            //Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                                object:self
                                                              userInfo:@{NOTIFICATION_KEY_URL: URLString,
                                                                         NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_FAILED
                                                                         }];
            
        }
    }
}

- (void)didAddDownloadForURLString:(NSString *)URLString {
}

- (void)didRejectDownloadForURLString:(NSString *)URLString {
}


#pragma mark Video management
- (void)markDownloadProgress:(float)progress forURL:(NSString *)URLString andVideoId:(NSString *)videoId{
    
    for (HelperVideoDownload * video in [self allVideos]) {
            if (([video.str_VideoURL isEqualToString:URLString] && video.state==DownloadStatePartial)
                ||[video.video_id isEqualToString:videoId]) {
                
                video.DownloadProgress = progress;
                video.isVideoDownloading = YES;
                if (progress==100) {
                    video.state = DownloadStateComplete;
                    video.isVideoDownloading=NO;
                    video.completedDate=[NSDate date];
                }
                else if (progress > 0) {
                     video.state = DownloadStatePartial;
                }
                else {
                    video.state = DownloadStateNew;
                    video.isVideoDownloading = NO;
                }
                
            }
       
    }

}


#pragma Video liast manangement


- (void)processData:(NSData *)data forType:(NSString *)URLString usingOfflineCache:(BOOL)offline{
    
    //Check if data type needs parsing
    if ([EdXInterface isURLForVideo:URLString]) {
        return;
    }
    else if ([EdXInterface isURLForImage:URLString]) {
        
    }
    else
    {
        //Get object
        id object = [_parser parsedObjectWithData:data forURLString:URLString];
        if (!object) {
            return;
        }
        
        //Take action based on object type
        if ([URLString isEqualToString:[self URLStringForType:URL_USER_DETAILS]]) {
            self.userdetail = (UserDetails *)object;
        }
        //download any additional data if required
        else if ([URLString isEqualToString:[self URLStringForType:URL_COURSE_ENROLLMENTS]]) {
            self.courses = (NSArray *)object;
            for (UserCourseEnrollment * courseEnrollment in _courses) {
                Course * course = courseEnrollment.course;
                
                //course enrolments, get images for background
                NSString * courseImage = course.course_image_url;
                NSString * imageDownloadURL = [NSString stringWithFormat:@"%@%@", [EDXEnvironment shared].config.apiHostURL, courseImage];
                
                BOOL force = NO;
                if (_commonDownloadProgress != -1) {
                    force = YES;
                }
                
                [self downloadWithRequestString:imageDownloadURL forceUpdate:force];
                
                //course subsection
                NSString * courseVideoDetails = course.video_outline;
                [self downloadWithRequestString:courseVideoDetails forceUpdate:force];
            }
        }
        //video outlines populate videos
        else if ([EdXInterface isURLForVideoOutline:URLString]) {
            
            NSArray * array = [_parser getVideosOfCourseWithURLString:URLString];
            [self storeVideoList:array forURL:URLString];
        }
        
        //If not using common download mode
        if (_commonDownloadProgress == -1) {
            //Delegate call back
        }
        else {
            _commonDownloadProgress++;
            [self downloadNextItem];
        }
    }
    
    
    //Post notification
    NSString * offlineValue = NOTIFICATION_VALUE_OFFLINE_NO;
    if (offline) {
        offlineValue = NOTIFICATION_VALUE_OFFLINE_YES;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                        object:self
                                                      userInfo:@{NOTIFICATION_KEY_URL: URLString,
                                                                 NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_SUCCESS,
                                                                 NOTIFICATION_KEY_OFFLINE: offlineValue,
                                                                 }];
}



- (void)storeVideoList:(NSArray *)videos forURL:(NSString *)URLString {
    
    Course *objCourse = [[Course alloc] init];
    
    for (UserCourseEnrollment *courseEnroll in _courses)
    {
        Course *obj = courseEnroll.course;
        if ([obj.video_outline isEqualToString:URLString])
        {
            objCourse=obj;
            break;
        }
    }
    
    //Add to dict
    [_courseVideos setObject:videos forKey:URLString];
    NSMutableDictionary *dictVideoData=[[NSMutableDictionary alloc] init];
    /// Added for debugging
    int partiallyDownloaded=0;
    int newVideos=0;
    int downloadCompleted=0;
    
    NSArray *array=[_storage getAllLocalVideoData];
    for (VideoData *videoData in array) {
        if(videoData.video_id){
            [dictVideoData setObject:videoData forKey:videoData.video_id];
        }
    }
    
    //Check in DB
    for (HelperVideoDownload * video in videos) {
        VideoData * data = [dictVideoData objectForKey:video.video_id];
        
        DownloadState downloadState=[data.download_state intValue];
        
        video.course_id = objCourse.course_id;
        video.course_url = objCourse.video_outline;
        
        if (!data) {
            downloadState=DownloadStateNew;
            video.watchedState = PlayedStateUnwatched;
            video.lastPlayedInterval = 0 ;
        }else{
            video.watchedState=[data.played_state intValue];
            video.lastPlayedInterval=[data.last_played_offset integerValue];
        }
        switch (downloadState) {
            case DownloadStateNew:
                video.isVideoDownloading = NO;
                newVideos++;
                break;
            case DownloadStatePartial:
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

- (NSMutableArray *)videosForChaptername:(NSString *)chapter
                          andSectionName:(NSString *)section
                                  forURL:(NSString *)URLString
{
    NSMutableArray * array = [[NSMutableArray alloc] init];
    for (HelperVideoDownload * video in [_courseVideos objectForKey:URLString])
    {
        if ([video.ChapterName isEqualToString:chapter]) {
            
            if (section) {
                if ([video.SectionName isEqualToString:section]) {
                    [array addObject:video];
                }
            }
            else
            {
                [array addObject:video];
            }
        }
    }
    return array;
}

- (NSMutableArray *)coursesAndVideosForDownloadState:(DownloadState)state {
    
    NSMutableArray * mainArray = [[NSMutableArray alloc] init];
    
    for (UserCourseEnrollment * courseEnrollment in _courses) {
        Course * course = courseEnrollment.course;
        //Videos array
        NSMutableArray * videosArray = [[NSMutableArray alloc] init];
        
        for (HelperVideoDownload * video in [_courseVideos objectForKey:course.video_outline]) {
            
            //Complete
            if (video.state == DownloadStateComplete && state == DownloadStateComplete) {
                [videosArray addObject:video];
            }
            //Partial
            else if (video.state == DownloadStatePartial && video.DownloadProgress < 100 && state == DownloadStatePartial) {
                [videosArray addObject:video];
            }
            else if (video.state == DownloadStateNew && state == DownloadStateNew) {
                [videosArray addObject:video];
            }
        }
        
        if (videosArray.count > 0) {
            NSDictionary * dict = @{CAV_KEY_COURSE:course,
                                    CAV_KEY_VIDEOS:videosArray};
            [mainArray addObject:dict];
        }
    }
    return mainArray;
}

- (NSArray *)allVideos {
    
    NSMutableArray * mainArray = [[NSMutableArray alloc] init];
    
    for (UserCourseEnrollment * courseEnrollment in _courses) {
        Course * course = courseEnrollment.course;
        
        for (HelperVideoDownload * video in [_courseVideos objectForKey:course.video_outline]) {
            [mainArray addObject:video];
        }
    }
    
    return mainArray;
}


- (HelperVideoDownload *)getSubsectionNameForSubsectionID:(NSString *)subsectionID
{
    for (UserCourseEnrollment * courseEnrollment in _courses)
    {
        Course * course = courseEnrollment.course;
        
        for (HelperVideoDownload * video in [_courseVideos objectForKey:course.video_outline])
        {
            if ([video.subSectionID isEqualToString:subsectionID])
            {
                return video;
            }
        }
    }

    return nil;
}


- (NSArray *)allVideosForState:(DownloadState)state {
    
    NSMutableArray * mainArray = [[NSMutableArray alloc] init];
    
    for (UserCourseEnrollment * courseEnrollment in _courses) {
        Course * course = courseEnrollment.course;
        
        for (HelperVideoDownload * video in [_courseVideos objectForKey:course.video_outline]) {
            //Complete
            if ((video.DownloadProgress == 100) && (state == DownloadStateComplete)) {
                [mainArray addObject:video];
            }
            //Partial
            else if ((video.isVideoDownloading && (video.DownloadProgress < 100)) && (state == DownloadStatePartial)) {
                [mainArray addObject:video];
            }
            else if (!video.isVideoDownloading && (state == DownloadStateNew)) {
                [mainArray addObject:video];
            }
        }
    }
    
    return mainArray;
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSInteger count=[self doDownloadMultipleVideosForRequestStrings:_multipleDownloadArray];
        if ( count > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FL_MESSAGE
                                                                object:self
                                                              userInfo:@{FL_ARRAY: _multipleDownloadArray}];
        }
    }
    else
    {
        self.multipleDownloadArray = nil;
    }
}


#pragma mark - Bulk Download
- (float)showBulkProgressViewForChapter:(NSString *)strChapName andSectionName:(NSString *)section
{
    AppDelegate *appD = [[UIApplication sharedApplication] delegate];
    
    NSMutableArray *arr_Videos = [self videosForChaptername:strChapName andSectionName:section forURL:appD.str_COURSE_OUTLINE_URL];
    
    float total = 0;
    float done = 0;
    float totalProgress = -1;
    NSInteger count = 0;
    
    for (HelperVideoDownload *objvideo in arr_Videos)
    {
        if (objvideo.state==DownloadStateNew)
        {
            return -1;
        }
        else if (objvideo.state==DownloadStatePartial)
        {
            total += 100;
            done += objvideo.DownloadProgress;
            totalProgress = (float)done / (float)total;
        }
        else
        {
            count++;
            if (count == [arr_Videos count]) {
                return -1;
            }
        }
    }
    
    return totalProgress;
}




#pragma mark - SRT bulk download
- (void)downloadBulkTranscripts:(HelperVideoDownload *)obj;
{
    // Download Chinese
    if (obj.HelperSrtChinese)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtChinese downloadIfNotAvailable:NO];
        if (!data)
            [self downloadWithRequestString:obj.HelperSrtChinese forceUpdate:YES];
    }
    
    // Download English
    if (obj.HelperSrtEnglish)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtEnglish downloadIfNotAvailable:NO];
        if (!data)
            [self downloadWithRequestString:obj.HelperSrtEnglish forceUpdate:YES];
    }
    
    // Download German
    if (obj.HelperSrtGerman)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtGerman downloadIfNotAvailable:NO];
        if (!data)
            [self downloadWithRequestString:obj.HelperSrtGerman forceUpdate:YES];
    }
    
    // Download Portuguese
    if (obj.HelperSrtPortuguese)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtPortuguese downloadIfNotAvailable:NO];
        if (!data)
            [self downloadWithRequestString:obj.HelperSrtPortuguese forceUpdate:YES];
    }
    
    // Download Spanish
    if (obj.HelperSrtSpanish)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtSpanish downloadIfNotAvailable:NO];
        if (!data)
            [self downloadWithRequestString:obj.HelperSrtSpanish forceUpdate:YES];
    }
    
}


#pragma mark - Download Video 

-(void)startDownloadForVideo:(HelperVideoDownload *)video completionHandler:(void(^)(BOOL sucess))completionHandler {
    AppDelegate *appD=[[UIApplication sharedApplication] delegate];
    if ([EdXInterface isURLForVideo:video.str_VideoURL])
    {
        if ([EdXInterface shouldDownloadOnlyOnWifi])
        {
            if (![appD.reachability isReachableViaWiFi])
            {
                completionHandler(NO);
                return;
            }
        }
    }
    [self addVideoForDownload:video completionHandler:completionHandler];
    
}


-(void)addVideoForDownload:(HelperVideoDownload *)video completionHandler:(void(^)(BOOL sucess))completionHandler {
    
    __block VideoData *data = [_storage videoDataForVideoID:video.video_id];
    if(!data){
        
        data = [self insertVideoData:video];
        
        [_storage startedDownloadForURL:video.str_VideoURL andVideoId:video.video_id];
    }
    
    NSArray *array=[_storage getVideosForDownloadUrl:video.str_VideoURL];
    if([array count]>1){
        for (VideoData *videoObj in array) {
            if([videoObj.download_state intValue]==DownloadStateComplete){
                [_storage completedDownloadForVideo:data];
                video.DownloadProgress=100;
                video.isVideoDownloading=NO;
                video.state=DownloadStateComplete;
                completionHandler(YES);
                return;
            }
        }
    }
    
    if(data){
        [[DownloadManager sharedManager] downloadVideoForObject:data withCompletionHandler:^(NSURLSessionDownloadTask *downloadTask) {
            if(downloadTask){
            video.state=DownloadStatePartial;
            video.DownloadProgress=0.1;
            video.isVideoDownloading=YES;
            completionHandler(YES);
            }else{
            completionHandler(NO);
            }
        }];
    }
    
}

// Cancel Video download
-(void)cancelDownloadForVideo:(HelperVideoDownload *)video completionHandler:(void (^) (BOOL))completionHandler{
    
    VideoData *data = [_storage videoDataForVideoID:video.video_id];
    
    if(data){
        [[DownloadManager sharedManager] cancelDownloadForVideo:data completionHandler:^(BOOL success) {
            video.state=DownloadStateNew;
            video.DownloadProgress=0;
            video.isVideoDownloading=NO;
            completionHandler(success);
            
        }];
    }else{

        video.isVideoDownloading=NO;
        video.DownloadProgress=0;
        video.state=DownloadStateNew;
    }
}


- (void)resumePausedDownloads {
    
     [_downloadManger resumePausedDownloads];
}


#pragma mark Video Management

-(DownloadState)stateForVideo:(HelperVideoDownload *)video{
    
    return [self.storage videoStateForVideoID:video.video_id];
    
}
-(PlayedState)watchedStateForVideo:(HelperVideoDownload *)video{
    
    return [self.storage watchedStateForVideoID:video.video_id];
}

- (float)lastPlayedIntervalForVideo:(HelperVideoDownload *)video{
    
    return [_storage lastPlayedIntervalForVideoID:video.video_id];
}

- (void)markVideoState:(PlayedState)state forVideo:(HelperVideoDownload *)video{
    
    if(video.video_id){
        [self.storage markPlayedState:state forVideoID:video.video_id];
    }
    
}

- (void)markDownloadState:(DownloadState)state forVideo:(HelperVideoDownload *)video{
    
    for (HelperVideoDownload * videoObj in [self allVideos]) {
        if ([videoObj.video_id isEqualToString:video.video_id]) {
            videoObj.state = state;
            if (state == DownloadStateNew) {
                videoObj.isVideoDownloading = NO;
                videoObj.DownloadProgress = 0.0;
            }
        }
    }
}


- (void)markLastPlayedInterval:(float)playedInterval forVideo:(HelperVideoDownload *)video{
    
    [_storage markLastPlayedInterval:playedInterval forVideoID:video.video_id];
    
}
#pragma mark - Closed Captioning
- (void)downloadTranscripts:(HelperVideoDownload *)obj;
{
    TranscriptsData *obj_Transcripts = [[TranscriptsData alloc] init];
    obj_Transcripts.ChineseDownloadURLString = obj.HelperSrtChinese;
    obj_Transcripts.EnglishDownloadURLString = obj.HelperSrtEnglish;
    obj_Transcripts.GermanDownloadURLString = obj.HelperSrtGerman;
    obj_Transcripts.PortugueseDownloadURLString = obj.HelperSrtPortuguese;
    obj_Transcripts.SpanishDownloadURLString = obj.HelperSrtSpanish;
    obj_Transcripts.FrenchDownloadURLString = obj.HelperSrtFrench;
    
    
    // Download Chinese
    if (obj.HelperSrtChinese)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtChinese downloadIfNotAvailable:NO];
        if (!data)
        {

            [self downloadWithRequestString:obj.HelperSrtChinese forceUpdate:YES];
            
        }
        
        obj_Transcripts.ChineseURLFilePath = [FileUtility completeFilePathForUrl:obj.HelperSrtChinese];
  }
    
    
    
    // Download English
    if (obj.HelperSrtEnglish)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtEnglish downloadIfNotAvailable:NO];
        if (!data)
        {
            [self downloadWithRequestString:obj.HelperSrtEnglish forceUpdate:YES];
            
        }
        
        obj_Transcripts.EnglishURLFilePath = [FileUtility completeFilePathForUrl:obj.HelperSrtEnglish];
    }
    
    
    
    // Download German
    if (obj.HelperSrtGerman)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtGerman downloadIfNotAvailable:NO];
        if (!data)
        {
            [self downloadWithRequestString:obj.HelperSrtGerman forceUpdate:YES];
            
        }
        
        obj_Transcripts.GermanURLFilePath = [FileUtility completeFilePathForUrl:obj.HelperSrtGerman];
    }
    
    
    
    // Download Portuguese
    if (obj.HelperSrtPortuguese)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtPortuguese downloadIfNotAvailable:NO];
        if (!data)
        {
            
            [self downloadWithRequestString:obj.HelperSrtPortuguese forceUpdate:YES];
            
        }
        
        obj_Transcripts.PortugueseURLFilePath = [FileUtility completeFilePathForUrl:obj.HelperSrtPortuguese];
    }
    
    
    
    // Download Spanish
    if (obj.HelperSrtSpanish)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtSpanish downloadIfNotAvailable:NO];
        if (!data)
        {
            [self downloadWithRequestString:obj.HelperSrtSpanish forceUpdate:YES];
        }
        
        obj_Transcripts.SpanishURLFilePath = [FileUtility completeFilePathForUrl:obj.HelperSrtSpanish];
    }
    
    // Download French
    if (obj.HelperSrtFrench)
    {
        NSData *data = [self resourceDataForURLString:obj.HelperSrtFrench downloadIfNotAvailable:NO];
        if (!data)
        {
            [self downloadWithRequestString:obj.HelperSrtFrench forceUpdate:YES];
        }
        
        obj_Transcripts.FrenchURLFilePath = [FileUtility completeFilePathForUrl:obj.HelperSrtFrench];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TRANSCRIPT object:self userInfo:@{KEY_TRANSCRIPT: obj_Transcripts}];
    
}

#pragma mark DownloadManagerDelegate

-(void)downloadTaskDidComplete:(NSURLSessionDownloadTask *)task{
    
    
}

-(void)downloadTask:(NSURLSessionDownloadTask *)task didCOmpleteWithError:(NSError *)error{
    NSArray  *array=[_storage videosForTaskIdentifier:task.taskIdentifier];
    for (VideoData *video in array) {
        video.dm_id=[NSNumber numberWithInt:0];
        video.download_state=[NSNumber numberWithInt:DownloadStateNew];
        
    }
    [self markDownloadProgress:0.0 forURL:[task.originalRequest.URL absoluteString] andVideoId:nil];
    
    [_storage saveCurrentStateToDB];
    
 }

-(void)downloadAlreadyInProgress:(NSURLSessionDownloadTask *)task{
    
    
}


-(void)dealloc{

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

- (NSString *)getFormattedDate
{
    NSDate *date = [NSDate date];
    NSDateFormatter *format  = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSSSSSZ"];
    NSString *strdate = [[NSString alloc] init];
    strdate = [format stringFromDate:date];

    NSString *substringFirst = [strdate substringToIndex:29];
    NSString *substringsecond = [strdate substringFromIndex:29];
    strdate = [NSString stringWithFormat:@"%@:%@",substringFirst, substringsecond];
    return strdate;
}


- (void)updateLastVisitedModule:(NSString*)module
{
    if (!module)
        return;
    
    NSString *timestamp = [self getFormattedDate];

    // Set to DB first and then depending on the response the DB gets updated
    [self setLastAccessedDataToDB:module TimeStamp:timestamp];
    
    UserDetails *user = [EdxAuthentication getLoggedInUser];
    
    NSString* path = [NSString stringWithFormat:@"/api/mobile/v0.5/users/%@/course_status_info/%@", user.username , self.selectedCourseOnFront.course_id];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[EDXEnvironment shared].config.apiHostURL, path]]];
    
    [request setHTTPMethod:@"PATCH"];
    NSString *authValue = [NSString stringWithFormat:@"%@",[EdxAuthentication authHeaderForApiAccess]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    
    NSDictionary* dictionary = @{
                                 @"modification_date" : timestamp,
                                 @"last_visited_module_id" : module
                                 };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSString* result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//       
//        ELog(@"last_visited_module_id result is %@", result);
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        NSArray *visitedPath = [dict objectForKey:@"last_visited_module_path"];
        
        NSString *subsectionID;
        
        for (NSString *subs in visitedPath)
        {
            if ([subs rangeOfString:@"sequential"].location != NSNotFound)
            {
                subsectionID = [visitedPath objectAtIndex:2];
                break;
            }
        }

        if (![module isEqualToString:subsectionID])
        {
            [self setLastAccessedDataToDB:subsectionID TimeStamp:timestamp];
        }


    }] resume];
}



- (void)setLastAccessedDataToDB:(NSString *)subsectionID TimeStamp:(NSString *)timestamp
{
    HelperVideoDownload *video = [self getSubsectionNameForSubsectionID:subsectionID];
    
    [self setLastAccessedSubsectionWith:subsectionID andSubsectionName:video.SectionName forCourseID:self.selectedCourseOnFront.course_id OnTimeStamp:timestamp];
}



- (void)getLastVisitedModule
{
    UserDetails *user = [EdxAuthentication getLoggedInUser];
    
    NSString* path = [NSString stringWithFormat:@"/api/mobile/v0.5/users/%@/course_status_info/%@", user.username , self.selectedCourseOnFront.course_id];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[EDXEnvironment shared].config.apiHostURL, path]]];
    
    [request setHTTPMethod:@"GET"];
    NSString *authValue = [NSString stringWithFormat:@"%@",[EdxAuthentication authHeaderForApiAccess]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSString* result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        
//        ELog(@"getLastVisitedModule result is %@", result);
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        NSArray *visitedPath = [dict objectForKey:@"last_visited_module_path"];
        
        NSString *subsectionID;
        
        for (NSString *subs in visitedPath)
        {
            if ([subs rangeOfString:@"sequential"].location != NSNotFound)
            {
                subsectionID = [visitedPath objectAtIndex:2];
                break;
            }
        }
        
        if (subsectionID)
        {
            NSString *timestamp = [self getFormattedDate];
            // Set to DB first and then depending on the response the DB gets updated
            [self setLastAccessedDataToDB:subsectionID TimeStamp:timestamp];

            //Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_URL_RESPONSE
                                                                object:self
                                                              userInfo:@{NOTIFICATION_KEY_URL: NOTIFICATION_VALUE_URL_LASTACCESSED,
                                                                         NOTIFICATION_KEY_STATUS: NOTIFICATION_VALUE_URL_STATUS_SUCCESS
                                                                         }];
        }
        
        
    }] resume];
}




#pragma mark - Analytics Call


- (void)sendAnalyticsEvents:(VideoStateAnalytics)state WithCurrentTime:(NSTimeInterval)currentTime
{
    if (isnan(currentTime))
    {
        currentTime = 0;
    }
    
    switch (state)
    {
        case VideoStateLoading:
            
            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStateStopped");
            
            if (self.selectedVideoUsedForAnalytics.video_id)
            {
                [Analytics trackVideoLoading:self.selectedVideoUsedForAnalytics.video_id
                                    CourseID:self.selectedCourseOnFront.course_id
                                     UnitURL:self.selectedVideoUsedForAnalytics.unit_url];
            }
            
            break;
            
        case VideoStateStop:
            
            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStateStopped");
            
            if (self.selectedVideoUsedForAnalytics.video_id)
            {
                [Analytics trackVideoStop:self.selectedVideoUsedForAnalytics.video_id
                              CurrentTime:currentTime
                                 CourseID:self.selectedCourseOnFront.course_id
                                  UnitURL:self.selectedVideoUsedForAnalytics.unit_url];
            }
            
            break;
            
        case VideoStatePlay:
            
            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStatePlaying");
            
            if (self.selectedVideoUsedForAnalytics.video_id)
            {
                [Analytics trackVideoPlaying:self.selectedVideoUsedForAnalytics.video_id
                                 CurrentTime:currentTime
                                    CourseID:self.selectedCourseOnFront.course_id
                                     UnitURL:self.selectedVideoUsedForAnalytics.unit_url];
            }
            
            break;
            
            
        case VideoStatePause:
            
            ELog(@"EdxInterface sendAnalyticsEvents ==>> MPMoviePlaybackStatePaused");
            if (self.selectedVideoUsedForAnalytics.video_id)
            {
                // MOB - 395
                [Analytics trackVideoPause:self.selectedVideoUsedForAnalytics.video_id
                               CurrentTime:currentTime
                                  CourseID:self.selectedCourseOnFront.course_id
                                   UnitURL:self.selectedVideoUsedForAnalytics.unit_url];
            }
            
            break;
            
            
        default:
            break;
    }
    
}


#pragma mark deactivate user interface
- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler
{
    ELog(@"deactivateWithCompletionHandler -1");
    if(!_network){
        completionHandler();
        return;
    }
    [_network deactivateWithCompletionHandler:^{
        ELog(@"complete");
        ELog(@"deactivateWithCompletionHandler -2");
        if(!_downloadManger){
            completionHandler();
            return ;
        }
        [_downloadManger deactivateWithCompletionHandler:^{
            [_parser deactivate];
            [_storage deactivate];
            [EdxAuthentication clearUserSessoin];
            self.userdetail = nil;
            self.courses = nil;
            self.courseVideos = nil;
            self.signInID = nil;
            self.signInUserName = nil;
            self.signInPassword = nil;
            self.parser = nil;
            self.numberOfRecentDownloads = 0;
            self.selectedCourseOnFront = nil;
            self.selectedVideoUsedForAnalytics = nil;
            completionHandler();
        }];
        
    }];
}


# pragma  mark activate interface for user

-(void)activateIntefaceForUser:(UserDetails *)user{
  
    // Reset Default Settings
    
    _sharedInterface.shownOfflineView=NO;

    // Used for CC
    _sharedInterface.selectedCourseOnFront = [[Course alloc] init];
    _sharedInterface.selectedVideoUsedForAnalytics = [[HelperVideoDownload alloc] init];
    _sharedInterface.selectedCCIndex = -1;
    _sharedInterface.selectedVideoSpeedIndex = -1;
    self.courseVideos = [[NSMutableDictionary alloc] init];

    NSString *key=[NSString stringWithFormat:@"%@_numberOfRecentDownloads", user.username];
    NSInteger recentDownloads=[[NSUserDefaults standardUserDefaults] integerForKey:key];
    //Downloads
    self.numberOfRecentDownloads = (int)recentDownloads;
    
    [FileUtility userDirectory];
    _storage=[StorageFactory getInstance];
    _downloadManger.delegate=self;
    _network.delegate=self;
    [_network activate];
    self.parser = [[DataParser alloc] initWithDataInterface:self];
    [[DownloadManager sharedManager] activateDownloadManager];
    [self backgroundInit];


    //timed function
    if([_timer isValid]){
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
