//
//  NetworkManager.m
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 05/05/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import "OEXNetworkManager.h"
#import "OEXAppDelegate.h"
#import "VideoData.h"
#import "OEXAuthentication.h"
#import "OEXInterface.h"
#import "OEXHelperVideoDownload.h"
#import "OEXUserDetails.h"
#import "OEXStorageFactory.h"
#define BACKGROUND_SESSION_KEY @"com.edx.backgroundSession"
#define VIDEO_BACKGROUND_SESSION_KEY @"com.edx.videoBackgroundSession"

@interface OEXNetworkManager ()
@property (nonatomic, strong) id<OEXStorageInterface>  storage;
@end

static OEXNetworkManager *_sharedManager = nil;

@implementation OEXNetworkManager

#pragma mark Public

- (id)init {
    
    self = [super init];
    [self activate];
    return self;
}

- (void)initBackgroundSession {
    
    if (!_backgroundSession) {
        //Configuration
        NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        if([OEXAuthentication authHeaderForApiAccess]){
            NSDictionary * headers=[NSDictionary dictionaryWithObjectsAndKeys:[OEXAuthentication authHeaderForApiAccess],@"Authorization", nil ];
            [backgroundConfiguration setHTTPAdditionalHeaders:headers];
        }
        //Session
        self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration
                                                               delegate:self
                                                          delegateQueue:nil];
    }
    
    
}

- (void)initForegroundSession {
    if (!_foregroundSession) {
        
        //Configurarion
        NSURLSessionConfiguration *foregroundConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        //Session
        if([OEXAuthentication authHeaderForApiAccess]){
            NSDictionary * headers=[NSDictionary dictionaryWithObjectsAndKeys:[OEXAuthentication authHeaderForApiAccess],@"Authorization", nil ];
            [foregroundConfig setHTTPAdditionalHeaders:headers];
            
        }
        
        self.foregroundSession = [NSURLSession sessionWithConfiguration:foregroundConfig
                                                               delegate:self
                                                          delegateQueue:nil];
        
    }
}



-(void)downloadInBackground:(NSURL *)url {
    if([OEXInterface isURLForVideo:url.absoluteString]){
       return;
    }
    [self checkIfURLUnderProcess:url];
}

- (void)cancelDownloadForURL:(NSURL *)url completionHandler:(void (^)(BOOL success))completionHandler {
   
    NSString *urlString=[url absoluteString];
    if(url){
    [[self sessionForRequest:url] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        BOOL found = NO;
        
        for (int ii = 0; ii < [downloadTasks count]; ii++) {
            
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:ii];
            NSURL *existingURL = downloadTask.originalRequest.URL;
            if ([[url absoluteString] isEqualToString:[existingURL absoluteString]]) {
                found = YES;
                [downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                    //Delete from DB
                    [_storage deleteResourceDataForURL:urlString];
                    //Completion handler
                    completionHandler(YES);
                }];
                break;
            }
        }
        if (!found) {
            //Delete from DB
            [_storage deleteResourceDataForURL:urlString];
             completionHandler(NO);
        }
    }];
  }
}

#pragma mark Functions
- (void)URLAlreadyUnderProcess:(NSURL *)URL {
    [_delegate downloadAlreadyExistsForURL:URL];
}

- (void)startBackgroundDownloadForSession:(NSURLSession *)session withURL:(NSURL *)url {
    if (!session) {
        //ELog(@"session missing!!!");
    }
    //Request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //Task
    NSURLSessionDownloadTask * downloadTask = nil;
    downloadTask = [session downloadTaskWithRequest:request];
    
    [downloadTask resume];
}

- (void)processURLInBackground:(NSURL *)url {
    
    [self startBackgroundDownloadForSession:[self sessionForRequest:url] withURL:url];
    
    //Notify delegate
    [_delegate downloadAddedForURL:url];
}

- (void)checkIfURLUnderProcess:(NSURL *)url {
    
    //Check if null
    if (!url || [url.absoluteString isEqualToString:@""]) {
        return;
    }
    
    [[self sessionForRequest:url] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        //Check if already downloading
        BOOL alreadyInProgress = NO;
        for (int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:ii];
            NSURL *existingURL = downloadTask.originalRequest.URL;
            
            if ([[url absoluteString] isEqualToString:[existingURL absoluteString]]) {
                alreadyInProgress = YES;
                break;
            }
        }
        
        if (alreadyInProgress) {
            [self performSelectorOnMainThread:@selector(URLAlreadyUnderProcess:) withObject:url waitUntilDone:NO];
        }
        else {
            [self performSelectorOnMainThread:@selector(processURLInBackground:) withObject:url waitUntilDone:NO];
        }
        
    }];
}

- (void)pauseAllActiveDownloadsWithCompletionHandler:(void (^)(void))completionHandler
{
    if(_backgroundSession){
    
    [_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks)
     {
         ELog(@"downloading tasks %lu", (unsigned long)downloadTasks.count);
         if (downloadTasks.count > 0) {
            __block NSInteger savedCount=0;
             
             for (int i=0; i<[downloadTasks count]; i++) {
           
                 NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:i];
                 ELog(@"Cancelling   downloading for url.....%@",[downloadTask.originalRequest.URL absoluteString]);
                 
                 [downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                     savedCount++;
                }];
             }
             completionHandler();
             return ;
         }
         else {
             completionHandler();
             return;
         }
     }];
    }else{
        
        completionHandler();
        
    }
}

#pragma mark Helpers

- (NSURLSession *)sessionForRequest:(NSURL *)URL
{
    if ([OEXInterface isURLForedXDomain:URL.absoluteString]) {
        return _backgroundSession;
    }
    else {
        return _backgroundSession;
    }
}

#pragma mark Initializations

+ (id)sharedManager {
    if (!_sharedManager) {
        _sharedManager = [[OEXNetworkManager alloc] init];
        [_sharedManager initBackgroundSession];
        [_sharedManager initForegroundSession];
        
    }
    
    return _sharedManager;
}

+ (void)clearNetworkManager{
    
    _sharedManager=nil;
    
}

- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler {
    _storage=nil;
    [self pauseAllActiveDownloadsWithCompletionHandler:^{
        
        [self.backgroundSession invalidateAndCancel];
        [self.foregroundSession invalidateAndCancel];
        self.backgroundSession = nil;
        self.foregroundSession = nil;
        
        completionHandler();
    }];
}

- (void)activate {
    self.storage = [OEXStorageFactory getInstance];
    [self initBackgroundSession];
    [self initForegroundSession];
    
}


#pragma mark NSURLSession Delegate methods

- (BOOL)isValidSession:(NSURLSession *)session {
    if (session == _backgroundSession || session == _foregroundSession) {
        return YES;
    }
    return NO;
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    //ELog(@"URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error \n '%@'", [error description]);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if ([self isValidSession:session]) {
        //ELog(@"URLSessionDidFinishEventsForBackgroundURLSession");
        //invoke background session completion handler
        [self invokeBackgroundSessionCompletionHandlerForSession:session];
    }
}

#pragma mark NSURLSessionDownload delegate methods

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didFinishDownloadingToURL:(NSURL *)location
{
    
    if (![self isValidSession:session])
    {
        return;
    }
    
   __block NSData* data = [NSData dataWithContentsOfURL:location];
   __block NSString *fileUrl=[OEXFileUtility completeFilePathForUrl:[downloadTask.originalRequest.URL absoluteString]];
    
    //Write data in main thread
    dispatch_async(dispatch_get_main_queue(), ^{

        if (fileUrl && _storage)
        {
            if ([data writeToURL:[NSURL fileURLWithPath:fileUrl] options:NSDataWritingAtomic error:nil] )
            {
               //notify
                [[NSNotificationCenter defaultCenter] postNotificationName:DL_COMPLETE
                                                                    object:self
                                                                  userInfo:@{DL_COMPLETE_N_TASK: downloadTask}];
                ELog(@"Resource DATA SAVED : %@", [downloadTask.originalRequest.URL absoluteString]);

            }
            else {
                ELog(@"Data not saved");
            }
        }
        else {
            ELog(@"Data meta data not found, not saved.");
        }
    });
    
    //invoke background session completion handler
    [self invokeBackgroundSessionCompletionHandlerForSession:session];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {

}

#pragma mark NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    if (![self isValidSession:session]) { return; }
    if(error && _storage){
    [_storage deleteResourceDataForURL:[task.originalRequest.URL absoluteString]];
    [_delegate receivedFaliureforTask:task];
    }
}

#pragma mark NSURLDataTask Delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    if (![self isValidSession:session]) { return; }
    
    //Status
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = (int)[httpResponse statusCode];
    if (responseStatusCode != 200) {
        //ELog(@"Data Task failed for request [%@], Error [%d]", dataTask.taskDescription, responseStatusCode);
        [_delegate receivedFaliureforTask:dataTask];
        return;
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    if (![self isValidSession:session]) { return; }
    
    //ELog(@"NSURLDataTask didReceiveData");
    [_delegate receivedData:data forTask:dataTask];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    //ELog(@"URLSession : didBecomeDownloadTask");
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    //ELog(@"URLSession : willCacheResponse");
}


-(void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)redirectResponse
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler{
    
    if (![self isValidSession:session]) { return; }
    
    NSMutableURLRequest *mutablerequest = [request mutableCopy];
    NSString *authValue = [NSString stringWithFormat:@"%@",[OEXAuthentication authHeaderForApiAccess]];
    [mutablerequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    
    completionHandler([mutablerequest copy]);
    
}


- (void)invokeBackgroundSessionCompletionHandlerForSession:(NSURLSession *)session
{
}



@end
