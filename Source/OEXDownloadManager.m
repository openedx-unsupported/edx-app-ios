//
//  DownloadManager.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 10/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXDownloadManager.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"
#import <Crashlytics/Crashlytics.h>
#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXFileUtility.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXSession.h"
#import "OEXStorageInterface.h"
#import "OEXStorageFactory.h"
#import "OEXUserDetails.h"

static OEXDownloadManager* _downloadManager = nil;

#define VIDEO_BACKGROUND_DOWNLOAD_SESSION_KEY @"com.edx.videoDownloadSession"

static NSURLSession* videosBackgroundSession = nil;

@interface OEXDownloadManager () <NSURLSessionDownloadDelegate>
{
}
@property(nonatomic, weak) id <OEXStorageInterface>storage;
@property(nonatomic, strong) NSMutableDictionary* dictVideoData;
@property(nonatomic, assign) BOOL isActive;
@end
@implementation OEXDownloadManager

+ (OEXDownloadManager*)sharedManager {
    if(!_downloadManager || [_downloadManager isKindOfClass:[NSNull class]]) {
        _downloadManager = nil;
        _downloadManager = [[OEXDownloadManager alloc] init];
        [_downloadManager initializeSession];
    }
    return _downloadManager;
}

- (void)initializeSession {
    NSURLSessionConfiguration* backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:VIDEO_BACKGROUND_DOWNLOAD_SESSION_KEY];

    backgroundConfiguration.allowsCellularAccess = YES;

    //Session
    videosBackgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _dictVideoData = [[NSMutableDictionary alloc] init];
    _isActive = YES;
}

- (id <OEXStorageInterface>)storage {
    if(_isActive) {
        return [OEXStorageFactory getInstance];
    }
    else {
        return nil;
    }
}

- (void)activateDownloadManager {
    _isActive = YES;
}

- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler {
    [self.storage pausedAllDownloads];
    _isActive = NO;
    [self pauseAllDownloadsForUser:[OEXSession sharedSession].currentUser.username completionHandler:^{
        // [videosBackgroundSession invalidateAndCancel];
        // _downloadManager=nil;
        completionHandler();
    }];
}

- (void)resumePausedDownloads {
    __weak typeof(self) weakSelf = self;
    OEXLogInfo(@"DOWNLOADS", @"Resuming Paused downloads");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array = [weakSelf.storage getVideosForDownloadState:OEXDownloadStatePartial];
        for(VideoData* data in array) {
            NSString* file = [OEXFileUtility filePathForVideoURL:data.video_url username:[OEXSession sharedSession].currentUser.username];
            if([[NSFileManager defaultManager] fileExistsAtPath:file]) {
                data.download_state = [NSNumber numberWithInt:OEXDownloadStateComplete];
                continue;
            }
            [weakSelf downloadVideoForObject:data withCompletionHandler:^(NSURLSessionDownloadTask* downloadTask) {
                    if(downloadTask) {
                        data.dm_id = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
                    }
                    else {
                        data.dm_id = [NSNumber numberWithInt:0];
                    }
                }];
        }
        [weakSelf.storage saveCurrentStateToDB];
    });
}

//Start Download for video
- (void)downloadVideoForObject:(VideoData*)video withCompletionHandler:(void (^)(NSURLSessionDownloadTask* downloadTask))completionHandler {
    [self checkIfVideoIsDownloading:video withCompletionHandler:completionHandler];
}

// Start Download for video Url
- (void)checkIfVideoIsDownloading:(VideoData*)video withCompletionHandler:(void (^)(NSURLSessionDownloadTask* downloadTask))completionHandler {
    //Check if null
    if(!video.video_url || [video.video_url isEqualToString:@""]) {
        OEXLogError(@"DOWNLOADS", @"Download Manager Empty/Corrupt URL, ignoring");
        video.download_state = [NSNumber numberWithInt: OEXDownloadStateNew];
        video.dm_id = [NSNumber numberWithInt:0];
        [self.storage saveCurrentStateToDB];
        completionHandler(nil);
        return;
    }

    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks) {
        //Check if already downloading
        BOOL alreadyInProgress = NO;
        __block NSInteger taskIndex = NSNotFound;
        for(int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:ii];
            NSURL* existingURL = downloadTask.originalRequest.URL;
            if([video.video_url isEqualToString:[existingURL absoluteString]]) {
                alreadyInProgress = YES;
                taskIndex = ii;
                break;
            }
        }
        if(alreadyInProgress) {
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:taskIndex];
            video.download_state = [NSNumber numberWithInt:OEXDownloadStatePartial];
            video.dm_id = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
            [self.storage saveCurrentStateToDB];
            completionHandler(downloadTask);
        }
        else {
            [self startDownloadForVideo:video WithCompletionHandler:completionHandler];
        }
    }];
}

- (void)saveDownloadTaskIdentifier:(NSInteger )taskIdentifier forVideo:(VideoData*)video {
    video.dm_id = [NSNumber numberWithUnsignedInteger:taskIdentifier];
    [self.storage saveCurrentStateToDB];
}

- (void)startDownloadForVideo:(VideoData*)video WithCompletionHandler:(void (^)(NSURLSessionDownloadTask* downloadTask))completionHandler {
    NSURLSessionDownloadTask* _downloadTask = [self startBackgroundDownloadForVideo:video];
    completionHandler(_downloadTask);
}

- (NSData*)resumeDataForURLString:(NSString*)URLString {
    NSString* filePath = [OEXFileUtility filePathForRequestKey:URLString];
    
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    return data;
}

- (BOOL )writeData:(NSData*)data atFilePath:(NSString*)filePath {
    //check if file already exists, delete it
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError* error;
        if([[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if(!success) {
                //NSLog(@"Error removing file at path: %@", error.localizedDescription);
            }
        }
    }
    
    //write new file
    if(![data writeToFile:filePath atomically:YES]) {
        OEXLogError(@"DOWNLOADS", @"There was a problem saving resume data to file ==>> %@", filePath);
        return NO;
    }
    
    return YES;
}

- (NSURLSessionDownloadTask*)startBackgroundDownloadForVideo:(VideoData*)video {
    //Request
    NSURL* url = [NSURL URLWithString:video.video_url];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    //Task
    NSURLSessionDownloadTask* downloadTask = nil;
    //Check if already exists
    OEXDownloadState state = [video.download_state intValue];
    if(state == OEXDownloadStatePartial) {
        if(video) {
            //Get resume data
            NSData* resumedata = [self resumeDataForURLString:video.video_url];
            if(resumedata && ![resumedata isKindOfClass:[NSNull class]]) {
                OEXLogError(@"DOWNLOADS", @"Download resume for video %@ with resume data", video.title);
                downloadTask = [videosBackgroundSession downloadTaskWithResumeData:resumedata];
            }
            else {
                downloadTask = [videosBackgroundSession downloadTaskWithRequest:request];
            }
        }
        //If not, start a fresh download
        else {
            downloadTask = [videosBackgroundSession downloadTaskWithRequest:request];
            video.download_state = [NSNumber numberWithInt: OEXDownloadStatePartial];
        }
    }
    else {
        downloadTask = [videosBackgroundSession downloadTaskWithRequest:request];
        video.download_state = [NSNumber numberWithInt: OEXDownloadStatePartial];
    }

    //Update DB
    video.download_state = [NSNumber numberWithInt: OEXDownloadStatePartial];
    video.dm_id = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    [self.storage saveCurrentStateToDB];
    [downloadTask resume];
    return downloadTask;
}

- (void)cancelDownloadForVideo:(VideoData*)video completionHandler:(void (^)(BOOL success))completionHandler {
    //// Check if two downloading  video refer to same download task
    /// If YES then just change the  state for video that we wqnt to cancel download .

    NSArray* array = [self.storage getVideosForDownloadUrl:video.video_url];
    int refcount = 0;
    for(VideoData* objVideo in array) {
        if([objVideo.download_state intValue] == OEXDownloadStatePartial) {
            refcount++;
        }
    }
    if(refcount >= 2) {
        [self.storage cancelledDownloadForVideo:video];
        completionHandler(YES);
        return;
    }

    //Cancel downloading videos

    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks) {
        BOOL found = NO;

        for(int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:ii];
            NSURL* existingURL = downloadTask.originalRequest.URL;

            if([video.video_url isEqualToString:[existingURL absoluteString]]) {
                found = YES;
                [downloadTask cancel];
                [self.storage cancelledDownloadForVideo:video];
                completionHandler(YES);
                break;
            }
        }
        if(!found) {
            [self.storage cancelledDownloadForVideo:video];
            completionHandler(NO);
        }
    }];
}

- (void)cancelAllDownloadsForUser:(NSString*)user completionHandler:(void (^)(void))completionHandler {
    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks) {
        for(int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask* task = [downloadTasks objectAtIndex:ii];
            [task cancel];
        }
        NSArray* array = [self.storage getVideosForDownloadState:OEXDownloadStatePartial];
        for(VideoData * video in array) {
            video.download_state = [NSNumber numberWithInt: OEXDownloadStateNew];
            video.dm_id = [NSNumber numberWithInt:0];
        }
        [self.storage saveCurrentStateToDB];
        completionHandler();
    }];
}

- (void)pauseAllDownloadsForUser:(NSString*)user completionHandler:(void (^)(void))completionHandler {
    _delegate = nil;
    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks) {
        __block int cancelledCount = 0;
        __block void (^ handler)(void) = [completionHandler copy];
        __block NSString* userName = [user copy];
        __block int taskCount = (int)[downloadTasks count];

        for(int ii = 0; ii < [downloadTasks count]; ii++) {
            __block NSURLSessionDownloadTask* task = [downloadTasks objectAtIndex:ii];
            [task cancelByProducingResumeData:^(NSData* resumeData) {
                    if(user) {
                        if(resumeData) {
                            NSString* resume = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
                            OEXLogInfo(@"DOWNLOADS", @"Resume data written at path %@ ==>> \n %@", [OEXFileUtility filePathForRequestKey:[task.originalRequest.URL absoluteString] username:userName], resume);
                            [self writeData:resumeData atFilePath:[OEXFileUtility filePathForRequestKey:[task.originalRequest.URL absoluteString] username:userName]];
                        }
                    }
                    cancelledCount++;
                    if(cancelledCount == taskCount) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                                handler();
                            });
                    }
                }];
        }

        if([downloadTasks count] == 0) {
            completionHandler();
        }
    }];
}

+ (void)clearDownloadManager {
    [_downloadManager cancelAllDownloadsForUser:[OEXSession sharedSession].currentUser.username completionHandler:^{
        _downloadManager = nil;
    }];
    _downloadManager = nil;
}

#pragma Download Task Delegte

- (BOOL)isValidSession:(NSURLSession*)session {
    if(session == videosBackgroundSession) {
        return YES;
    }
    return NO;
}

#pragma NSURLSession Delegate

- (void)URLSession:(NSURLSession*)session didBecomeInvalidWithError:(NSError*)error {
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession*)session {
    if(session.configuration.identifier) {
        [self invokeBackgroundSessionCompletionHandlerForSession:session];
    }
}

- (void)invokeBackgroundSessionCompletionHandlerForSession:(NSURLSession*)session {
    if(![self isValidSession:session]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        OEXAppDelegate* appDelegate = (OEXAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate callCompletionHandlerForSession:session.configuration.identifier];
    });
}

#pragma mark NSURLSessionDownload delegate methods

- (void)           URLSession:(NSURLSession*)session
                 downloadTask:(NSURLSessionDownloadTask*)downloadTask
    didFinishDownloadingToURL:(NSURL*)location {
    if(!session.configuration.identifier) {
        return;
    }

    OEXLogInfo(@"DOWNLOADS", @"Download complete delegate get called ");

    __block NSData* data = [NSData dataWithContentsOfURL:location];
    if(!data) {
        OEXLogInfo(@"DOWNLOADS", @"Data is Null for downloaded file. Location ==>> %@ ", location);
    }

    __block NSString* downloadUrl = [downloadTask.originalRequest.URL absoluteString];
    __block NSString* fileurl = [OEXFileUtility filePathForVideoURL:downloadUrl username:[OEXSession sharedSession].currentUser.username];
    dispatch_async(dispatch_get_main_queue(), ^{
        if([[NSFileManager defaultManager] fileExistsAtPath:fileurl]) {
            [[NSFileManager defaultManager] removeItemAtPath:fileurl error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[fileurl stringByDeletingPathExtension] error:nil];
        }
        if(fileurl) {
            NSError* error;
            if([data writeToURL:[NSURL fileURLWithPath:fileurl] options:NSDataWritingAtomic error:&error]) {
                OEXLogInfo(@"DOWNLOADS", @"Downloaded Video get saved at ==>> %@", fileurl);

                NSArray* videos = [self.storage getAllDownloadingVideosForURL:downloadUrl];

                for(VideoData* videoData in videos) {
                    OEXLogInfo(@"DOWNLOADS", @"Updating record for Downloaded Video ==>> %@", videoData.title);

                    [[OEXAnalytics sharedAnalytics] trackDownloadComplete:videoData.video_id CourseID:videoData.enrollment_id UnitURL:videoData.unit_url];

                    [self.storage completedDownloadForVideo:videoData];
                }

                //// Dont notify to ui if app is running in background
                if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                    OEXLogInfo(@"DOWNLOADS", @"Sending download complete");

                    //notify
                    [[NSNotificationCenter defaultCenter] postNotificationName:OEXDownloadEndedNotification
                                                                        object:self
                                                                      userInfo:@{VIDEO_DL_COMPLETE_N_TASK: downloadTask}];
                }
            }
            else {
                OEXLogInfo(@"DOWNLOADS", @"Video not saved Error:-fileurl ==>> %@ ", fileurl);
                OEXLogInfo(@"DOWNLOADS", @"writeToFile failed with ==> %@", [error localizedDescription]);
                NSArray* videos = [self.storage getAllDownloadingVideosForURL:downloadUrl];
                for(VideoData* videoData in videos) {
                    [self.storage cancelledDownloadForVideo:videoData];
                }
            }
        }
    });
    [self invokeBackgroundSessionCompletionHandlerForSession:session];
}

- (void)           URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if(![self isValidSession:session]) {
        return;
    }

    ///Update progress only when application is active

    //    if([[UIApplication sharedApplication] applicationState] ==UIApplicationStateActive){
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PROGRESS_NOTIFICATION
                                                            object:nil
                                                          userInfo:@{DOWNLOAD_PROGRESS_NOTIFICATION_TASK: downloadTask,
                                                                     DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE: [NSNumber numberWithDouble:(double)totalBytesExpectedToWrite],
                                                                     DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN: [NSNumber numberWithDouble:(double)totalBytesWritten]}];
    });
}

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error {
    OEXLogInfo(@"DOWNLOADS", @" Download failed with error ==>>%@ ", [error localizedDescription]);
    if([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
        if(error) {
            OEXLogInfo(@"DOWNLOADS", @"%@ download failed with error ==>> %@ ", [[[task originalRequest] URL] absoluteString], [error localizedDescription]);
            //            if([self.delegate respondsToSelector:@selector(downloadTask:didCOmpleteWithError:)]){
            //                [self.delegate downloadTask:downloadTask didCOmpleteWithError:error];
            //            }
        }
    }
}

- (void)    URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask
     didResumeAtOffset:(int64_t)fileOffset
    expectedTotalBytes:(int64_t)expectedTotalBytes {
    //NSLog(@"---- resumed ----");
}

- (NSString*)keyForDownloadTask:(NSURLSessionDownloadTask*)downloadTask {
    NSString* strTaskID = [NSString stringWithFormat:@"%@_%lu", [OEXSession sharedSession].currentUser.username, (unsigned long)downloadTask.taskIdentifier];
    return strTaskID;
}

@end

