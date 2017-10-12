//
//  OEXDBManager.m
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014-2016 edX, Inc. All rights reserved.
//

#import "OEXDBManager.h"

#import "edX-Swift.h"
#import <Crashlytics/Crashlytics.h>
#import "LastAccessed.h"
#import "Logger+OEXObjC.h"
#import "OEXFileUtility.h"
#import "OEXUserDetails.h"
#import "OEXSession.h"
#import "VideoData.h"

static OEXDBManager* _sharedManager = nil;

@interface OEXDBManager ()
@property (nonatomic, strong) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext* masterManagedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property(nonatomic, strong) NSOperationQueue* operationQueue;
@property(nonatomic, strong) NSMutableDictionary* dictFetchedRecords;
@property(nonatomic, strong) NSManagedObjectContext* backGroundContext;

@property(nonatomic, strong) NSString* userName;
- (NSManagedObjectContext*)masterManagedObjectContext;
@end

@implementation OEXDBManager

#pragma appdelegate code

- (void)createDatabaseDirectory {
    //File URL
    NSString* basePath = [OEXFileUtility userDirectory];
    NSString* videosDirectory = [basePath stringByAppendingPathComponent:@"Database"];

    if(![[NSFileManager defaultManager] fileExistsAtPath:videosDirectory]) {
        NSError* error;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:videosDirectory
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:&error]) {
            OEXLogError(@"STORAGE", @"Failed to create database directory  at %@", basePath);
        }
        OEXLogInfo(@"STORAGE", @"Database directory created at %@", basePath);
    }
}

- (void)openDatabaseForUser:(NSString*)userName {
    if(![self.userName isEqualToString:userName]) {
        [self createDatabaseDirectory];
        _userName = userName;
        if(_masterManagedObjectContext != nil) {
            [_backGroundContext save:nil];
            [_masterManagedObjectContext save:nil];
            _backGroundContext = nil;
            _masterManagedObjectContext = nil;
        }

        if([self masterManagedObjectContext]) {
            NSString* basePath = [OEXFileUtility userDirectory];
            NSString* databasePath = [basePath stringByAppendingPathComponent:@"Database"];

            OEXLogInfo(@"STORAGE", @"Database opened Sucessfully %@ ", databasePath);

            _backGroundContext = [self newManagedObjectContext];
        }
    }
}

- (void)closeDatabse {
    [self deactivate];
}

- (void)deactivate {
    OEXLogInfo(@"STORAGE", @"Deactivating database");
    [self saveCurrentStateToDB];
    [self.backGroundContext reset];
    [self.masterManagedObjectContext reset];
    self.managedObjectModel = nil;
    self.persistentStoreCoordinator = nil;
    self.backGroundContext = nil;
    self.userName = nil;
    _sharedManager = nil;
    [_dictFetchedRecords removeAllObjects];
}

- (NSManagedObjectContext*)masterManagedObjectContext {
    if(_masterManagedObjectContext != nil) {
        return _masterManagedObjectContext;
    }
    NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
    if(coordinator != nil) {
        self.masterManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_masterManagedObjectContext performBlockAndWait:^{
            [_masterManagedObjectContext setPersistentStoreCoordinator:coordinator];
        }];
    }
    return _masterManagedObjectContext;
}

- (NSManagedObjectModel*)managedObjectModel {
    if(_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
    if(_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    NSString* storePath = [[OEXFileUtility userDirectory] stringByAppendingPathComponent:@"Database/edXDB.sqlite"];
    NSURL* storeURL = [NSURL fileURLWithPath:storePath];
    
    OEXLogInfo(@"STORAGE", @"DB path %@", storeURL);

    NSError* error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        OEXLogInfo(@"STORAGE", @"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext*)newManagedObjectContext {
    NSManagedObjectContext* newContext = nil;
    NSManagedObjectContext* masterContext = _masterManagedObjectContext;
    if(masterContext != nil) {
        newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [newContext performBlockAndWait:^{
            [newContext setParentContext:masterContext];
        }];
    }
    return newContext;
}

- (NSManagedObjectContext*)backGroundContext {
    if(_backGroundContext) {
        return _backGroundContext;
    }
    else if(_masterManagedObjectContext) {
        return [self newManagedObjectContext];
    }
    else {
        return nil;
    }
}

//===================================================================================================================//
#pragma mark - Singleton method

+ (OEXDBManager*)sharedManager {
    if(!_sharedManager) {
        OEXUserDetails* user = [[OEXSession sharedSession] currentUser];
        if(user) {
            _sharedManager = [[OEXDBManager alloc] init];
            [_sharedManager openDatabaseForUser:user.username];
        }
        else {
            _sharedManager = nil;
        }
    }
    return _sharedManager;
}

- (void)initializeDB {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!_operationQueue) {
            _operationQueue = [[NSOperationQueue alloc] init];
        }
    });
    _dictFetchedRecords = [[NSMutableDictionary alloc] init];
}

- (void)activate {
}

// Save all table data at a time
- (void)saveCurrentStateToDB {
    OEXLogInfo(@"STORAGE", @"Save database context on main thread");
    CLS_LOG(@"saveCurrentStateToDB");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        @synchronized(_masterManagedObjectContext){
            [self.backGroundContext save:nil];
            CLS_LOG(@"saveCurrentStateToDB: backGroundContext... %@", self.backGroundContext);
            CLS_LOG(@"saveCurrentStateToDB: masterManagedObjectContext... %@", self.masterManagedObjectContext);
            [self.masterManagedObjectContext save:nil];
            NSError* error = nil;
            if(_masterManagedObjectContext != nil) {
                if([_masterManagedObjectContext hasChanges] && ![_masterManagedObjectContext save:&error]) {
                    OEXLogInfo(@"STORAGE", @"Could not save changes to database");
                }
            }
        }
    }];
}

- (NSEntityDescription*)getEntityByName:(NSString*)entityName {
    if(self.backGroundContext) {
        @synchronized(_backGroundContext)
        {
            NSEntityDescription* videoEntity = [NSEntityDescription entityForName:entityName inManagedObjectContext:_backGroundContext];
            return videoEntity;
        }
    }
    return nil;
}

- (NSArray*)executeFetchRequest:(NSFetchRequest*)fetchRequest {
    CLS_LOG(@"executeFetchRequest");
    if([self masterManagedObjectContext]) {
        CLS_LOG(@"executeFetchRequest: masterManagedObjectContext exist...%@", _masterManagedObjectContext);
        __block NSArray* resultArray;
        if([NSThread isMainThread]) {
            @synchronized(_masterManagedObjectContext)
            {
                CLS_LOG(@"executeFetchRequest: executeFetchRequest in main thread");
                resultArray = [[self masterManagedObjectContext] executeFetchRequest:fetchRequest error:nil];
            }
        }
        else {
            [_backGroundContext performBlockAndWait:^{
                CLS_LOG(@"executeFetchRequest: executeFetchRequest in performBlockAndWait with %@", _backGroundContext);
                resultArray = [self.backGroundContext executeFetchRequest:fetchRequest error:nil];
            }];
        }

        if(!resultArray) {
            return [NSArray array];
        }
        else {
            return resultArray;
        }
    }
    else {
        return nil;
    }
}

#pragma mark - Existing methods refactored with new DB

#pragma mark - ResourceData Method

- (void)updateData:(NSData*)data ForURLString:(NSString*)URLString {
    //File path
    NSString* filePath = [OEXFileUtility filePathForRequestKey:URLString];
    //check if file already exists, delete it
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError* error;
        if([[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if(!success) {
                OEXLogError(@"STORAGE", @"Error removing file at path: %@", error.localizedDescription);
            }
        }
    }
    //write new file
    if(![data writeToFile:filePath atomically:YES]) {
        OEXLogError(@"STORAGE", @"There was a problem saving json to file");
    }
}

// Insert Resource data
- (void)insertResourceDataForURL:(NSString*)resourceDownloadURL {
    if([self resourceDataForURL:resourceDownloadURL]) {
        return;
    }
    ResourceData* resourceObj = [NSEntityDescription insertNewObjectForEntityForName:@"ResourceData"
                                                              inManagedObjectContext:_backGroundContext];
    resourceObj.resourceDownloadURL = resourceDownloadURL;
    [self saveCurrentStateToDB];
}

// Get the resource data (JSON/image,etc.) for a URL
- (ResourceData*)resourceDataForURL:(NSString*)URL {
    //   ResourceData *result;
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* resourceEntity = [self getEntityByName:@"ResourceData"];
    [fetchRequest setEntity:resourceEntity];
    NSPredicate* query = [NSPredicate predicateWithFormat:@"resourceDownloadURL==%@", URL];
    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];
    //  ELog(@"resourceDataForURL : %@",resultArray);
    return (ResourceData*)[resultArray firstObject];
}

// Set if the resource is completed
- (void)completedDownloadForResourceURL:(NSString*)URL {
    ResourceData* resourceData = [self resourceDataForURL:URL];
    if(resourceData) {
        resourceData.downloadState = [NSNumber numberWithFloat: OEXDownloadStateComplete];
        resourceData.downloadCompleteDate = [NSDate date];
        [self saveCurrentStateToDB];
    }
}

// Set if the resource is started
- (void)startedDownloadForResourceURL:(NSString*)URL {
    ResourceData* resourceData = [self resourceDataForURL:URL];
    if(resourceData) {
        resourceData.downloadState = [NSNumber numberWithFloat: OEXDownloadStatePartial];
        //[self saveCurrentStateToDB];
    }
    else {
        [self insertResourceDataForURL:URL];
    }
}

- (void)cancelledResourceDownloadForURL:(NSString*)url {
    ResourceData* newVideoData = [self resourceDataForURL:url];
    //Download State
    newVideoData.downloadState = [NSNumber numberWithInt: OEXDownloadStateNew];
    [self saveCurrentStateToDB];
}

- (void)deleteResourceDataForURL:(NSString*)url {
    ResourceData* dataToDelete = [self resourceDataForURL:url];
    NSString* filePath = [OEXFileUtility filePathForRequestKey:url];
    if(dataToDelete) {
        //Mark new in DB
        [self cancelledResourceDownloadForURL:url];
        //Delete file
        if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath
                                                       error:nil];
        }
        [self saveCurrentStateToDB];
    }
}

// Get the download state for resource
- (OEXDownloadState)downloadStateForResourceURL:(NSString*)URL {
    ResourceData* resourceData = [self resourceDataForURL:URL];

    return [resourceData.downloadState intValue];
}

- (NSData*)dataForURLString:(NSString*)URLString {
    NSString* filePath = [OEXFileUtility filePathForRequestKey:URLString];

    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData* data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }

    return nil;
}

#pragma mark - LastAccessed table methods

- (LastAccessed*)lastAccessedDataForCourseID:(NSString*)courseID {
    if(_masterManagedObjectContext) {
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"LastAccessed" inManagedObjectContext:_masterManagedObjectContext]];
        NSPredicate* query = [NSPredicate predicateWithFormat:@"course_id==%@", courseID];
        //setting the predicate to the fetch request
        [fetchRequest setPredicate:query];
        NSArray* resultArray = [self executeFetchRequest:fetchRequest];
        OEXLogInfo(@"STORAGE", @"loaded lastAccessedDataForCourseID : %@", resultArray);
        return [resultArray firstObject];
    }

    return nil;
}

- (void)setLastAccessedSubsection:(NSString*)subsectionID andSubsectionName:(NSString*)subsectionName forCourseID:(nullable NSString*)courseID OnTimeStamp:(NSString*)timestamp {
    if(_backGroundContext) {
        LastAccessed* lastAcc = [self lastAccessedDataForCourseID:courseID];
        if(!lastAcc) {
            LastAccessed* lastAcc = [NSEntityDescription insertNewObjectForEntityForName:@"LastAccessed"
                                                                  inManagedObjectContext:_backGroundContext];

            lastAcc.course_id = courseID;
            lastAcc.subsection_id = subsectionID;
            lastAcc.subsection_name = subsectionName;
            lastAcc.timestamp = timestamp;
        }
        else {
            lastAcc.subsection_id = subsectionID;
            lastAcc.subsection_name = subsectionName;
            lastAcc.timestamp = timestamp;
        }

        [self saveCurrentStateToDB];
    }
}

#pragma  mark - VideoData Table Methods

- (NSArray*)getAllLocalVideoData {
    CLS_LOG(@"getAllLocalVideoData");
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    CLS_LOG(@"getAllLocalVideoData: backGroundContext...%@", _backGroundContext);
    NSEntityDescription* videoEntity = [NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext];
    CLS_LOG(@"getAllLocalVideoData: getVideoEntity from manageObjectContect");
    [fetchRequest setEntity:videoEntity];
    return [self executeFetchRequest:fetchRequest];
}

- (VideoData*)getVideoDataForVideoID:(NSString*)videoId {
    return [self videoDataForVideoID:videoId];
}

- (VideoData*)videoDataForVideoID:(NSString*)video_id {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* videoEntity = [NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:self.backGroundContext];
    [fetchRequest setEntity:videoEntity];
    NSPredicate* query = [NSPredicate predicateWithFormat:@"video_id==%@", video_id];
    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];
    NSArray* resultArray = [self executeFetchRequest:fetchRequest];
    //   ELog(@"getVideoDataFor VideoID : %@",resultArray);

    return (VideoData*)[resultArray firstObject];
}

- (void)startedDownloadForURL:(NSString*)downloadUrl andVideoId:(NSString*)videoId {
    VideoData* newVideoData;

    newVideoData = [self videoDataForVideoID:videoId];

    if(!newVideoData) {
        newVideoData = [NSEntityDescription insertNewObjectForEntityForName:@"VideoData"
                                                     inManagedObjectContext:_backGroundContext];

        newVideoData.video_id = videoId;
    }

    //Download State
    newVideoData.download_state = [NSNumber numberWithInt: OEXDownloadStatePartial];

    [self saveCurrentStateToDB];
}

- (OEXDownloadState)videoStateForVideoID:(NSString*)video_id {
    VideoData* videoData = [self getVideoDataForVideoID:video_id];
    if(videoData) {
        return [videoData.download_state intValue];
    }

    return OEXDownloadStateNew;
}

- (OEXPlayedState)watchedStateForVideoID:(NSString*)video_id {
    VideoData* videoData = [self getVideoDataForVideoID:video_id];

    if(videoData) {
        return [videoData.played_state intValue];
    }
    return OEXPlayedStateUnwatched;
}

- (float)lastPlayedIntervalForVideoID:(NSString*)video_id {
    VideoData* videoData = [self getVideoDataForVideoID:video_id];
    if(videoData) {
        return [videoData.last_played_offset floatValue];
    }
    return 0.0;
}

- (void)markLastPlayedInterval:(float)playedInterval forVideoID:(NSString*)video_id {
    VideoData* videoData = [self getVideoDataForVideoID:video_id];

    if(videoData) {
        videoData.last_played_offset = [NSNumber numberWithFloat: playedInterval];
        [self saveCurrentStateToDB];
    }
}

- (void)markPlayedState:(OEXPlayedState)state forVideoID:(NSString*)video_id {
    VideoData* videoData = [self getVideoDataForVideoID:video_id];

    if(videoData) {
        videoData.played_state = [NSNumber numberWithFloat: state];
        [self saveCurrentStateToDB];
    }
}

- (NSData*)resumeDataForVideoID:(NSString*)video_id {
    NSData* data = nil;

    VideoData* videoData = [self getVideoDataForVideoID:video_id];
    if(!videoData) {
        return nil;
    }

    data = [[NSFileManager defaultManager] contentsAtPath:[OEXFileUtility filePathForRequestKey:videoData.video_url]];

    return data;
}

- (void)startedDownloadForVideo:(VideoData*)videoData {
    if(videoData) {
        videoData.download_state = [NSNumber numberWithFloat:OEXDownloadStatePartial];
        [self saveCurrentStateToDB];
    }
}

- (void)onlineEntryForVideo:(VideoData*)videoData {
    if(videoData) {
        videoData.download_state = [NSNumber numberWithFloat:OEXDownloadStateNew];
        [self saveCurrentStateToDB];
    }
}

- (void)completedDownloadForVideo:(VideoData*)videoData {
    if(videoData) {
        videoData.download_state = [NSNumber numberWithFloat:OEXDownloadStateComplete];
        videoData.downloadCompleteDate = [NSDate date];
        videoData.dm_id = [NSNumber numberWithInt:0];
        [self saveCurrentStateToDB];
    }
}

- (void)cancelledDownloadForVideo:(VideoData*)videoData {
    if(videoData) {
        videoData.download_state = [NSNumber numberWithFloat:OEXDownloadStateNew];
        videoData.dm_id = [NSNumber numberWithInt:0];
        [self deleteDataForVideoID:videoData.video_id];
        [self saveCurrentStateToDB];
    }
}

- (void)pausedAllDownloads {
    NSArray* array = [self getAllLocalVideoData];
    CLS_LOG(@"pausedAllDownloads: localVideoData...%@", array);
    for(VideoData* video in array) {
        CLS_LOG(@"pausedAllDownloads: VideoData...%@", video);
        if((video && [video isKindOfClass:[VideoData class]]) && ([video.download_state intValue] == OEXDownloadStatePartial || [video.dm_id intValue] != 0)) {
            video.dm_id = [NSNumber numberWithInt:0];
        }
    }

    [self saveCurrentStateToDB];
}

- (void)deleteDataForVideoID:(NSString*)video_id {
    VideoData* videoData = [self getVideoDataForVideoID:video_id];
    NSArray* arrVideo = [self getVideosForDownloadUrl:videoData.video_url];
    int referenceCount = 0;
    if([arrVideo count] > 1) {
        for(VideoData* video in arrVideo) {
            if([video.download_state intValue] == OEXDownloadStateComplete) {
                referenceCount++;
                if(referenceCount >= 2) {
                    break;
                }
            }
        }
    }
    //NSString * filePath = [NSString stringWithFormat:@"%@", videoData.filepath];
    if(videoData) {
        //Mark new in DB
        videoData.download_state = @(OEXDownloadStateNew);
        videoData.dm_id = @(0);
        [self saveCurrentStateToDB];
        //Delete file
        if(referenceCount <= 1) {
            [self deleteFileForURL:videoData.video_url];
        }
    }
}

- (void)deleteFileForURL:(NSString*)URL {
    [[NSFileManager defaultManager] removeItemAtPath:[OEXFileUtility filePathForVideoURL:URL username:[OEXSession sharedSession].currentUser.username]
                                               error:nil];

    [[NSFileManager defaultManager] removeItemAtPath:[OEXFileUtility filePathForRequestKey:URL]
                                               error:nil];
}

- (NSArray*)getVideosForDownloadUrl:(NSString*)downloadUrl {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];

    NSPredicate* query = [NSPredicate predicateWithFormat:@"video_url==%@", downloadUrl];
    [fetchRequest setPredicate:query];

    return [self executeFetchRequest:fetchRequest];
}

- (NSArray*)getVideosForDownloadState:(OEXDownloadState)state {
    CLS_LOG(@"getVideosForDownloadState");
    NSArray* allVideos = [self getAllLocalVideoData];
    NSMutableArray* filteredArray = [[NSMutableArray alloc] init];
    CLS_LOG(@"getVideosForDownloadState: videosForDownloadState...%@", allVideos);
    for(VideoData* data in allVideos) {
        if(data && ([data.download_state intValue] == state)) {
            [filteredArray addObject:data];
        }
    }

    return filteredArray;
}

- (NSArray*)getAllDownloadingVideosForURL:(NSString*)url {
    NSArray* allVideos = [self getVideosForDownloadUrl:url];
    NSMutableArray* filteredArray = [[NSMutableArray alloc] init];
    for(VideoData* data in allVideos) {
        if([data.download_state intValue] == OEXDownloadStatePartial || [data.dm_id intValue] != 0) {
            [filteredArray addObject:data];
        }
    }
    return filteredArray;
}

- (NSArray*)getAllDownloadingVideos {
    NSArray* allVideos = [self getAllLocalVideoData];
    NSMutableArray* filteredArray = [[NSMutableArray alloc] init];
    for(VideoData* data in allVideos) {
        if([data.download_state intValue] == OEXDownloadStatePartial || [data.dm_id intValue] != 0) {
            [filteredArray addObject:data];
        }
    }
    return filteredArray;
}

- (VideoData*)videoDataForTaskIdentifier:(NSUInteger)dTaskId {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];

    NSPredicate* query = [NSPredicate predicateWithFormat:@"dm_id==%lu", dTaskId];
    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];

    return (VideoData*)[resultArray firstObject];
}

- (NSArray*)videosForTaskIdentifier:(NSUInteger)dTaskId {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];
    NSPredicate* query = [NSPredicate predicateWithFormat:@"dm_id==%lu", dTaskId];
    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];
    NSArray* resultArray = [self executeFetchRequest:fetchRequest];
    return resultArray;
}

// Update the is_active column on refresh
- (void)unregisterAllEntries {
    NSArray* array = [self getAllLocalVideoData];

    for(VideoData* video in array) {
        video.is_registered = [NSNumber numberWithBool:NO];
    }

    [self saveCurrentStateToDB];
}

// Get all videos for enrollmentID
- (NSArray*)videosWithCourseID:(NSString*)courseid {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];
    NSPredicate* query = [NSPredicate predicateWithFormat:@"enrollment_id==%@", courseid];
    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];
    NSArray* resultArray = [self executeFetchRequest:fetchRequest];
    return resultArray;
}

// get all unregistered videos
- (void)deleteUnregisteredItems {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];
    NSPredicate* query = [NSPredicate predicateWithFormat:@"is_registered==%@", [NSNumber numberWithBool:NO]];
    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];

    for(VideoData* video in resultArray) {
        [self deleteFileForURL:video.video_url];
    }
    // deleting the video data only if the video is deleted in online of offline mode.
    for(NSManagedObject* managedObject in resultArray) {
        [[managedObject managedObjectContext] deleteObject:managedObject];
    }

    [self saveCurrentStateToDB];
}

- (void)setRegisteredCoursesAndDeleteUnregisteredData:(NSString*)courseid {
    NSArray* arrVideos = [self videosWithCourseID:courseid];

    for(VideoData* video in arrVideos) {
        video.is_registered = [NSNumber numberWithBool:YES];
    }

    [self saveCurrentStateToDB];
}

#pragma mark - POST GA DB Interface/Protocol Implementation

#pragma - insertion query
// All the operations will have a "where" clause to filter data as per the logged-in User.

//inserting the video data only if the video is played online or started downloading.

- (VideoData*)insertVideoData:(NSString*)username
                        Title:(NSString*)title
                         Size:(NSString*)size
                     Duration:(NSString*)duration
                DownloadState:(OEXDownloadState)download_state
                     VideoURL:(NSString*)video_url
                      VideoID:(NSString*)video_id
                      UnitURL:(NSString*)unit_url
                     CourseID:(NSString*)enrollment_id
                         DMID:(int)dm_id
                  ChapterName:(NSString*)chapter_name
                  SectionName:(NSString*)section_name
                    TimeStamp:(NSDate*)downloadCompleteDate
               LastPlayedTime:(float)last_played_offset
                       is_Reg:(BOOL)is_registered
                  PlayedState:(OEXPlayedState)played_state {
    VideoData* Checkdata = [self getVideoDataForVideoID:video_id];

    if(Checkdata && video_id != nil) {
        return Checkdata;
    }

    VideoData* videoObj = [NSEntityDescription insertNewObjectForEntityForName:@"VideoData"
                                                        inManagedObjectContext:_backGroundContext];

    videoObj.username = username;
    videoObj.title = title;
    videoObj.size = size;
    videoObj.duration = duration;
    videoObj.download_state = [NSNumber numberWithInt:download_state];
    videoObj.video_url = video_url;
    videoObj.video_id = video_id;
    videoObj.unit_url = unit_url;
    videoObj.enrollment_id = enrollment_id;
    videoObj.dm_id = [NSNumber numberWithUnsignedInteger:dm_id];
    videoObj.chapter_name = chapter_name;
    videoObj.section_name = section_name;
    videoObj.downloadCompleteDate = downloadCompleteDate;
    videoObj.last_played_offset = [NSNumber numberWithFloat:last_played_offset];
    videoObj.is_registered = [NSNumber numberWithBool:is_registered];
    videoObj.played_state = [NSNumber numberWithInt:played_state];

    [self saveCurrentStateToDB];

    return videoObj;
}

#pragma - deletion query

//deleting the video data only if the video is deleted in online of offline mode.
- (void)deleteVideoData:(NSString*)username
                       :(NSString*)video_id {
    NSArray* resultArray = [self getRecordsForOperation:username VideoID:video_id];

    for(NSManagedObject* managedObject in resultArray) {
        [_backGroundContext deleteObject:managedObject];
    }
}

#pragma - Fetch / selection query

//select the video data to show up for a user
- (NSArray*)getAllVideoDataFor:(NSString*)username {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];

    NSPredicate* query = [NSPredicate predicateWithFormat:@"username==%@", username];

    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];

    // ELog(@"getAllVideoData FOr Username : %@",resultArray);

    return resultArray;
}

- (NSArray*)getVideoDataFor:(NSString*)username
                    VideoID:(NSString*)video_id {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];

    NSPredicate* query = [NSPredicate predicateWithFormat:@"username==%@", username];

    NSPredicate* query1 = [NSPredicate predicateWithFormat:@"video_id==%@", video_id];

    NSPredicate* compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[query, query1]];

    //setting the predicate to the fetch request
    [fetchRequest setPredicate:compoundPredicate];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];

    OEXLogInfo(@"STORAGE", @"getVideoDataFor VideoID : %@", resultArray);

    return resultArray;
}

- (NSArray*)getVideoDataFor:(NSString*)username
               EnrollmentID:(NSString*)enrollment_id {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];

    NSPredicate* query = [NSPredicate predicateWithFormat:@"username==%@", username];

    NSPredicate* query1 = [NSPredicate predicateWithFormat:@"enrollment_id==%@", enrollment_id];

    NSPredicate* compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[query, query1]];

    //setting the predicate to the fetch request
    [fetchRequest setPredicate:compoundPredicate];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];

    OEXLogInfo(@"STORAGE", @"getVideoDataFor EnrollmentID : %@", resultArray);

    return resultArray;
}

#pragma - update query

- (NSArray*)getRecordsForOperation:(NSString*)username
                           VideoID:(NSString*)video_id {
    NSPredicate* query = [NSPredicate predicateWithFormat:@"username==%@ and video_id==%@", username, video_id];

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];

    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];

    return resultArray;
}

// Update the video data with last played time when playing is paused
- (void)updateLastPlayedTime:(NSString*)username
                     VideoID:(NSString*)video_id
          WithLastPlayedTime:(float)last_played_offset {
    NSArray* resultArray = [self getRecordsForOperation:username VideoID:video_id];

    if([resultArray count] > 0) {
        VideoData* videoObj = [resultArray objectAtIndex:0];
        videoObj.last_played_offset = [NSNumber numberWithFloat: last_played_offset];
        [self saveCurrentStateToDB];
    }
}

// Update the video data with download state
- (void)updateDownloadState:(NSString*)username
                    VideoID:(NSString*)video_id
          WithDownloadState:(int)download_state {
    NSArray* resultArray = [self getRecordsForOperation:username VideoID:video_id];

    if([resultArray count] > 0) {
        VideoData* videoObj = [resultArray objectAtIndex:0];
        videoObj.download_state = [NSNumber numberWithInt: download_state];
        [self saveCurrentStateToDB];
    }
}

// Update the video data with played state
- (void)updatePlayedState:(NSString*)username
                  VideoID:(NSString*)video_id
          WithPlayedState:(int)played_state {
    NSArray* resultArray = [self getRecordsForOperation:username VideoID:video_id];

    if([resultArray count] > 0) {
        VideoData* videoObj = [resultArray objectAtIndex:0];
        videoObj.played_state = [NSNumber numberWithInt: played_state];
        [self saveCurrentStateToDB];
    }
}

// Update the video downloaded timestamp
- (void)updateDownloadTimestamp:(NSString*)username
                        VideoID:(NSString*)video_id
                  WithTimeStamp:(NSDate*)downloadCompleteDate {
    NSArray* resultArray = [self getRecordsForOperation:username VideoID:video_id];

    if([resultArray count] > 0) {
        VideoData* videoObj = [resultArray objectAtIndex:0];
        videoObj.downloadCompleteDate = downloadCompleteDate;
        [self saveCurrentStateToDB];
    }
}

// Update the course state if it is registered or no
- (void)updateCourseRegisterState:(NSString*)username
                         CourseID:(NSString*)enrollment_id
                       Withis_Reg:(BOOL)is_registered {
    NSPredicate* query = [NSPredicate predicateWithFormat:@"username==%@ and enrollment_id==%@", username, enrollment_id];

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"VideoData" inManagedObjectContext:_backGroundContext]];

    //setting the predicate to the fetch request
    [fetchRequest setPredicate:query];

    NSArray* resultArray = [self executeFetchRequest:fetchRequest];

    if([resultArray count] > 0) {
        VideoData* videoObj = [resultArray objectAtIndex:0];
        videoObj.is_registered = [NSNumber numberWithBool:is_registered];
        [self saveCurrentStateToDB];
    }
}

@end
