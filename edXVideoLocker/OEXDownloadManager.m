//
//  DownloadManager.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 10/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXDownloadManager.h"
#import "OEXNetworkConstants.h"
#import "OEXAuthentication.h"
#import "OEXAppDelegate.h"
#import "OEXStorageInterface.h"
#import "OEXStorageFactory.h"
#import "OEXSession.h"
static OEXDownloadManager *_downloadManager=nil;

#define VIDEO_BACKGROUND_DOWNLOAD_SESSION_KEY @"com.edx.videoDownloadSession"

static NSURLSession *videosBackgroundSession = nil;

@interface OEXDownloadManager ()<NSURLSessionDownloadDelegate>
{
    
}
@property(nonatomic,weak)id<OEXStorageInterface>storage;
@property(nonatomic,assign)BOOL isActive;
@end
@implementation OEXDownloadManager


+(OEXDownloadManager *)sharedManager{
    if(!_downloadManager || [_downloadManager isKindOfClass:[NSNull class]]){
        _downloadManager=nil;
        _downloadManager=[[OEXDownloadManager alloc] init];
        [_downloadManager initializeSession];
    }
    return _downloadManager;
}

-(void)initializeSession{
    NSURLSessionConfiguration *backgroundConfiguration;
#ifdef __IPHONE_8_0
    if (IS_IOS8)
    {
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:VIDEO_BACKGROUND_DOWNLOAD_SESSION_KEY];
    }else
#endif
    {   // DEPRECATED in ios 8
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:VIDEO_BACKGROUND_DOWNLOAD_SESSION_KEY];
    }
    
    backgroundConfiguration.allowsCellularAccess=YES;
    
    //Session
     videosBackgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _isActive=YES;
}

-(id<OEXStorageInterface>)storage{
    if(_isActive){
        return [OEXStorageFactory getInstance];
    }else{
        return nil;
    }
}

-(void)activateDownloadManager{
    _isActive=YES;
}

- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler{
    [self.storage pausedAllDownloads];
    _isActive=NO;
    [self pauseAllDownloadsForUser:[OEXAuthentication getLoggedInUser].username completionHandler:^{
        // [videosBackgroundSession invalidateAndCancel];
        // _downloadManager=nil;
        completionHandler();
    }];
    
}

- (void)resumePausedDownloads {
    ELog(@"Resuming Paused downloads ");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        NSArray *array=[self.storage getVideosForDownloadState:OEXDownloadStatePartial];
        for (VideoData * data in array) {
            NSString *file=[OEXFileUtility localFilePathForVideoUrl:data.video_url];
            if([[NSFileManager defaultManager] fileExistsAtPath:file]){
                data.download_state=[NSNumber numberWithInt:OEXDownloadStateComplete];
                continue;
            }
            [self downloadVideoForObject:data withCompletionHandler:^(NSURLSessionDownloadTask *downloadTask) {
                if(downloadTask){
                    data.dm_id=[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
                }else{
                    data.dm_id=[NSNumber numberWithInt:0];
                }
            }];
        }
        [self.storage saveCurrentStateToDB];
    });
}

//Start Download for video
-(void)downloadVideoForObject:(VideoData *)video withCompletionHandler:(void (^)(NSURLSessionDownloadTask * downloadTask))completionHandler{
    [self checkIfVideoIsDownloading:video withCompletionHandler:completionHandler];
}


// Start Download for video Url
-(void)checkIfVideoIsDownloading:(VideoData *)video withCompletionHandler:(void (^)(NSURLSessionDownloadTask * downloadTask))completionHandler {
    //Check if null
    if (!video.video_url || [video.video_url isEqualToString:@""]) {
        ELog(@"Dowload Manager Empty/Corrupt URL, ignoring");
        video.download_state = [NSNumber numberWithInt: OEXDownloadStateNew];
        video.dm_id=[NSNumber numberWithInt:0];
        [self.storage saveCurrentStateToDB];
        completionHandler(nil);
        return;
    }
    
    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        //Check if already downloading
        BOOL alreadyInProgress = NO;
        __block  NSInteger taskIndex=NSNotFound;
        for (int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:ii];
            NSURL *existingURL = downloadTask.originalRequest.URL;
            if ([video.video_url isEqualToString:[existingURL absoluteString]]) {
                alreadyInProgress = YES;
                taskIndex=ii;
                break;
            }
        }
        if (alreadyInProgress) {
            NSURLSessionDownloadTask *downloadTask=[downloadTasks objectAtIndex:taskIndex];
            video.download_state=[NSNumber numberWithInt:OEXDownloadStatePartial];
            video.dm_id=[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
            [self.storage saveCurrentStateToDB];
            completionHandler(downloadTask);
        }
        else {
            [self startDownloadForVideo:video WithCompletionHandler:completionHandler];
        }
    }];
    
}

-(void)saveDownloadTaskIdentifier:(NSInteger )taskIdentifier forVideo:(VideoData *)video{
    
    video.dm_id=[NSNumber numberWithUnsignedInteger:taskIdentifier];
    [self.storage saveCurrentStateToDB];
    
}

-(void)startDownloadForVideo:(VideoData *)video WithCompletionHandler:(void (^)(NSURLSessionDownloadTask * downloadTask))completionHandler{
    
    NSURLSessionDownloadTask *_downloadTask= [self startBackgroundDownloadForVideo:video];
    completionHandler(_downloadTask);
    
}

- (NSURLSessionDownloadTask *)startBackgroundDownloadForVideo:(VideoData *)video {
    
    //Request
    NSURL *url=[NSURL URLWithString:video.video_url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //Task
    NSURLSessionDownloadTask * downloadTask = nil;
    //Check if already exists
    OEXDownloadState state = [video.download_state intValue];
    if (state == OEXDownloadStatePartial) {
        if (video) {
            //Get resume data
            NSData * resumedata =[OEXFileUtility resumeDataForURLString:video.video_url];
            if (resumedata && ![resumedata isKindOfClass:[NSNull class]]) {
                ELog(@"Download resume for video %@ with resume data ",video.title);
                downloadTask = [videosBackgroundSession downloadTaskWithResumeData:resumedata];
            }
            else {
                downloadTask = [videosBackgroundSession downloadTaskWithRequest:request];
            }
        }
        //If not, start a fresh download
        else {
            downloadTask = [videosBackgroundSession downloadTaskWithRequest:request];
            video.download_state=[NSNumber numberWithInt: OEXDownloadStatePartial];
        }
    }
    else {
        downloadTask = [videosBackgroundSession downloadTaskWithRequest:request];
        video.download_state=[NSNumber numberWithInt: OEXDownloadStatePartial];
    }
    
    //Update DB
    video.download_state = [NSNumber numberWithInt: OEXDownloadStatePartial];
    video.dm_id=[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    [self.storage saveCurrentStateToDB];
    [downloadTask resume];
    return downloadTask;
    
}


-(void)cancelDownloadForVideo:(VideoData *)video completionHandler:(void (^)(BOOL success))completionHandler{
    
    //// Check if two downloading  video refer to same download task
    /// If YES then just change the  state for video that we wqnt to cancel download .
    
    NSArray *array=[self.storage getVideosForDownloadUrl:video.video_url];
    int refcount=0;
    for (VideoData *objVideo in array) {
        if([objVideo.download_state  intValue]== OEXDownloadStatePartial){
            refcount++;
        }
    }
    if(refcount >=2){
        [self.storage cancelledDownloadForVideo:video];
        completionHandler(YES);
        return;
    }
    
    
    //Cancel downloading videos
    
    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        BOOL found = NO;
        
        for (int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:ii];
            NSURL *existingURL = downloadTask.originalRequest.URL;
            
            if ([video.video_url isEqualToString:[existingURL absoluteString]]) {
                found = YES;
                [downloadTask cancel];
                [self.storage cancelledDownloadForVideo:video];
                completionHandler(YES);
                break;
            }
        }
        if (!found) {
            [self.storage cancelledDownloadForVideo:video];
            completionHandler(NO);
        }
    }];
    
}

-(void)cancelAllDownloadsForUser:(NSString *)user completionHandler:(void (^)(void))completionHandler{
    
    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask *task=[downloadTasks objectAtIndex:ii];
            [task cancel];
        }
        NSArray *array= [self.storage getVideosForDownloadState:OEXDownloadStatePartial];
        for (VideoData *video in array) {
            video.download_state=[NSNumber numberWithInt: OEXDownloadStateNew];
            video.dm_id=[NSNumber numberWithInt:0];
        }
        [self.storage saveCurrentStateToDB];
        completionHandler();
    }];
}


-(void)pauseAllDownloadsForUser:(NSString *)user completionHandler:(void (^)(void))completionHandler{
    _delegate=nil;
    [videosBackgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        __block int cancelledCount=0;
        __block void (^handler)(void) =[completionHandler copy];
        __block NSString *userName=[user copy];
        __block int taskCount=(int)[downloadTasks count];
        
        for (int ii = 0; ii < [downloadTasks count]; ii++) {
            __block  NSURLSessionDownloadTask *task=[downloadTasks objectAtIndex:ii];
            [task cancelByProducingResumeData:^(NSData *resumeData) {
                if(user){
                    if(resumeData){
                        NSString *resume=[[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
                        ELog(@"Resume data written at path %@ ==>> \n %@",[OEXFileUtility completeFilePathForUrl:[task.originalRequest.URL absoluteString]andUserName:userName],resume);
                        [OEXFileUtility writeData:resumeData atFilePath:[OEXFileUtility completeFilePathForUrl:[task.originalRequest.URL absoluteString]andUserName:userName]];
                    }
                }
                cancelledCount++;
                if(cancelledCount==taskCount){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler();
                    });
                }
                
            }];
        }
        
        if([downloadTasks count]==0){
            completionHandler();
        }
        
    }];
}




+(void) clearDownlaodManager{
    [_downloadManager cancelAllDownloadsForUser:[OEXAuthentication getLoggedInUser].username completionHandler:^{
        _downloadManager=nil;
    }];
    _downloadManager=nil;
}

#pragma Download Task Delegte

- (BOOL)isValidSession:(NSURLSession *)session {
    if (session == videosBackgroundSession ) {
        return YES;
    }
    return NO;
}


#pragma NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (session.configuration.identifier) {
        [self invokeBackgroundSessionCompletionHandlerForSession:session];
    }
}

- (void)invokeBackgroundSessionCompletionHandlerForSession:(NSURLSession *)session
{
    if (![self isValidSession:session]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        OEXAppDelegate *appDelegate = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate callCompletionHandlerForSession:session.configuration.identifier];
    });
}

#pragma mark NSURLSessionDownload delegate methods

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    if (!session.configuration.identifier){
        return;
    }
    
    NSLog(@"Download complete delegate get called ");
    
    __block NSData* data = [NSData dataWithContentsOfURL:location];
    if(!data){
        NSLog(@"Data is Null for downloaded file. Location ==>> %@ ",location);
    }

    __block NSString *downloadUrl=[downloadTask.originalRequest.URL absoluteString];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
       if(_isActive )
        {
            NSString *fileurl= [OEXFileUtility localFilePathForVideoUrl:downloadUrl];
            if([[NSFileManager defaultManager] fileExistsAtPath:fileurl]){
                [[NSFileManager defaultManager] removeItemAtPath:fileurl error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:[fileurl stringByDeletingPathExtension] error:nil];
            }
            
            if(!fileurl){
                return ;
            }
            NSError *error;
            NSURL *file=[NSURL fileURLWithPath:fileurl];
            
            if(data!=nil &&[data writeToURL:file options:NSDataWritingAtomic error:&error])
            {
                
                ELog(@"Downloaded Video get saved at ==>> %@ ",fileurl);
                
                NSArray *videos=[self.storage getAllDownloadingVideosForURL:downloadUrl];
                
                for (VideoData *videoData in videos) {
                    
                    NSLog(@"Updating record for Downloaded Video ==>> %@ ",videoData.title);
                    
                    [OEXAnalytics trackDownloadComplete:videoData.video_id CourseID:videoData.enrollment_id UnitURL:videoData.unit_url];
                    [self.storage completedDownloadForVideo:videoData];
                }
                
                //// Dont notify to ui if app is running in background
                if([[UIApplication sharedApplication] applicationState] ==UIApplicationStateActive){
                    
                    ELog(@"Sending download complete ");
                    
                    //notify
                    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DL_COMPLETE
                                                                        object:self
                                                                      userInfo:@{VIDEO_DL_COMPLETE_N_TASK: downloadTask}];
                }
            }
            else {
                ELog(@"Video not saved Error:-fileurl ==>> %@ ", fileurl);
                ELog(@"writeToFile failed with ==> %@", [error localizedDescription]);
                NSArray *videos=[self.storage getAllDownloadingVideosForURL:downloadUrl];
                for (VideoData *videoData in videos) {
                    [self.storage cancelledDownloadForVideo:videoData];
                }
            }
            
        }
    });
    
    
    [self invokeBackgroundSessionCompletionHandlerForSession:session];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if (![self isValidSession:session] ) { return; }
    
    ///Update progress only when application is active
    
    //    if([[UIApplication sharedApplication] applicationState] ==UIApplicationStateActive){
    //
    if(_isActive){
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOAD_PROGRESS_NOTIFICATION
                                                            object:nil
                                                          userInfo:@{DOWNLOAD_PROGRESS_NOTIFICATION_TASK: downloadTask,
                                                                     DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE: [NSNumber numberWithDouble:(double)totalBytesExpectedToWrite],
                                                                     DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN: [NSNumber numberWithDouble:(double)totalBytesWritten]}];
    }
    
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if([task isKindOfClass:[NSURLSessionDownloadTask class]]){
        
        if(error){
            NSLog( @" Download failed with error ==>>%@ ",[error localizedDescription]);
            NSData *resumeData=[error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            if(resumeData){
                NSString *url=[task.originalRequest.URL absoluteString];
                NSString *filepath=[OEXFileUtility completeFilePathForUrl:url];
                NSError *error;
                if([[NSFileManager defaultManager] fileExistsAtPath:filepath]){
                    [[NSFileManager defaultManager] removeItemAtPath:filepath error:nil];
                }
                if(filepath){
                    NSURL *localFileUrl= [NSURL fileURLWithPath:filepath];
                    if([resumeData writeToURL:localFileUrl  options:NSDataWritingAtomic error:&error])
                    {
                        NSLog(@"Resume data  saved ==>> %@ ", filepath);
                    }else{
                        NSLog(@"Resume data not saved ==>> %@ ", filepath);
                        
                    }
                }
            }
        }else{
            NSString *url=[task.originalRequest.URL absoluteString];
            NSString *filepath=[OEXFileUtility completeFilePathForUrl:url];
            if([[NSFileManager defaultManager] fileExistsAtPath:filepath]){
                [[NSFileManager defaultManager] removeItemAtPath:filepath error:nil];
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    //NSLog(@"---- resumed ----");
}


-(NSString *)keyForDownloadTask:(NSURLSessionDownloadTask *)downloadTask{
    
    NSString *strTaskID=[NSString stringWithFormat:@"%@_%lu",[OEXAuthentication getLoggedInUser].username,(unsigned long)downloadTask.taskIdentifier];
    return strTaskID;
    
}

@end

