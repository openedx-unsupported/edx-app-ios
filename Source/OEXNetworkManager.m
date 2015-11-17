//
//  NetworkManager.m
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 05/05/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import "OEXNetworkManager.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXFileUtility.h"
#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXUserDetails.h"
#import "VideoData.h"

#define BACKGROUND_SESSION_KEY @"com.edx.backgroundSession"
#define VIDEO_BACKGROUND_SESSION_KEY @"com.edx.videoBackgroundSession"

@interface OEXNetworkManager ()
@end

static OEXNetworkManager* _sharedManager = nil;

@implementation OEXNetworkManager

#pragma mark Public

- (id)init {
    self = [super init];
    [self activate];
    return self;
}

- (void)initBackgroundSession {
    if(!_backgroundSession) {
        //Configuration
        NSURLSessionConfiguration* backgroundConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

        if([OEXAuthentication authHeaderForApiAccess]) {
            NSDictionary* headers = [NSDictionary dictionaryWithObjectsAndKeys:[OEXAuthentication authHeaderForApiAccess], @"Authorization", nil ];
            [backgroundConfiguration setHTTPAdditionalHeaders:headers];
        }
        //Session
        self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration
                                                               delegate:self
                                                          delegateQueue:nil];
    }
}

- (void)initForegroundSession {
    if(!_foregroundSession) {
        //Configurarion
        NSURLSessionConfiguration* foregroundConfig = [NSURLSessionConfiguration defaultSessionConfiguration];

        //Session
        if([OEXAuthentication authHeaderForApiAccess]) {
            NSDictionary* headers = [NSDictionary dictionaryWithObjectsAndKeys:[OEXAuthentication authHeaderForApiAccess], @"Authorization", nil ];
            [foregroundConfig setHTTPAdditionalHeaders:headers];
        }

        self.foregroundSession = [NSURLSession sessionWithConfiguration:foregroundConfig
                                                               delegate:self
                                                          delegateQueue:nil];
    }
}

- (void)downloadInBackground:(NSURL*)url {
    if([OEXInterface isURLForVideo:url.absoluteString]) {
        return;
    }
    [self checkIfURLUnderProcess:url];
}

#pragma mark Functions
- (void)URLAlreadyUnderProcess:(NSURL*)URL {
    [_delegate downloadAlreadyExistsForURL:URL];
}

- (void)startBackgroundDownloadForSession:(NSURLSession*)session withURL:(NSURL*)url {
    if(!session) {
        //ELog(@"session missing!!!");
    }
    //Request
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    //Task
    NSURLSessionDownloadTask* downloadTask = nil;
    downloadTask = [session downloadTaskWithRequest:request];

    [downloadTask resume];
}

- (void)processURLInBackground:(NSURL*)url {
    [self startBackgroundDownloadForSession:[self sessionForRequest:url] withURL:url];

    //Notify delegate
    [_delegate downloadAddedForURL:url];
}

- (void)checkIfURLUnderProcess:(NSURL*)url {
    //Check if null
    if(!url || [url.absoluteString isEqualToString:@""]) {
        return;
    }

    [[self sessionForRequest:url] getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks) {
        //Check if already downloading
        BOOL alreadyInProgress = NO;
        for(int ii = 0; ii < [downloadTasks count]; ii++) {
            NSURLSessionDownloadTask* downloadTask = [downloadTasks objectAtIndex:ii];
            NSURL* existingURL = downloadTask.originalRequest.URL;

            if([[url absoluteString] isEqualToString:[existingURL absoluteString]]) {
                alreadyInProgress = YES;
                break;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(alreadyInProgress) {
                [self URLAlreadyUnderProcess:url];
            }
            else {
                [self processURLInBackground:url];
            }
        });
    }];
}

- (void)pauseAllActiveDownloadsWithCompletionHandler {
    if(_backgroundSession) {
        [_backgroundSession invalidateAndCancel];
    }
}

#pragma mark Helpers

- (NSURLSession*)sessionForRequest:(NSURL*)URL {
    if([OEXInterface isURLForedXDomain:URL.absoluteString]) {
        return _backgroundSession;
    }
    else {
        return _backgroundSession;
    }
}

#pragma mark Initializations

+ (id)sharedManager {
    if(!_sharedManager) {
        _sharedManager = [[OEXNetworkManager alloc] init];
        [_sharedManager initBackgroundSession];
        [_sharedManager initForegroundSession];
    }

    return _sharedManager;
}

+ (void)clearNetworkManager {
    _sharedManager = nil;
}

- (void)invalidateNetworkManager {
    [self.backgroundSession invalidateAndCancel];
    [self.foregroundSession invalidateAndCancel];
    self.backgroundSession = nil;
    self.foregroundSession = nil;
}

- (void)activate {
    [self initBackgroundSession];
    [self initForegroundSession];
}

#pragma mark NSURLSession Delegate methods

- (BOOL)isValidSession:(NSURLSession*)session {
    if(session == _backgroundSession || session == _foregroundSession) {
        return YES;
    }
    return NO;
}

- (void)URLSession:(NSURLSession*)session didBecomeInvalidWithError:(NSError*)error {
    //ELog(@"URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error \n '%@'", [error description]);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession*)session {
    if([self isValidSession:session]) {
        //ELog(@"URLSessionDidFinishEventsForBackgroundURLSession");
        //invoke background session completion handler
        [self invokeBackgroundSessionCompletionHandlerForSession:session];
    }
}

#pragma mark NSURLSessionDownload delegate methods

- (void)           URLSession:(NSURLSession*)session
                 downloadTask:(NSURLSessionDownloadTask*)downloadTask
    didFinishDownloadingToURL:(NSURL*)location {
    if(![self isValidSession:session]) {
        return;
    }

    NSData* data = [NSData dataWithContentsOfURL:location];
    NSString* fileUrl = [OEXFileUtility filePathForRequestKey:[downloadTask.originalRequest.URL absoluteString]];

    //Write data in main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if(fileUrl) {
            if([data writeToURL:[NSURL fileURLWithPath:fileUrl] options:NSDataWritingAtomic error:nil]) {
                //notify
                [[NSNotificationCenter defaultCenter] postNotificationName:DL_COMPLETE
                                                                    object:self
                                                                  userInfo:@{DL_COMPLETE_N_TASK: downloadTask}];
                OEXLogInfo(@"NETWORK", @"Resource DATA SAVED : %@", [downloadTask.originalRequest.URL absoluteString]);
            }
            else {
                OEXLogInfo(@"NETWORK", @"Data not saved");
            }
        }
        else {
            OEXLogInfo(@"NETWORK", @"Data meta data not found, not saved.");
        }
    });

    //invoke background session completion handler
    [self invokeBackgroundSessionCompletionHandlerForSession:session];
}

- (void)           URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
}

- (void)    URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask
     didResumeAtOffset:(int64_t)fileOffset
    expectedTotalBytes:(int64_t)expectedTotalBytes {
}

#pragma mark NSURLSessionTaskDelegate methods

- (void)      URLSession:(NSURLSession*)session
                    task:(NSURLSessionTask*)task
    didCompleteWithError:(NSError*)error {
    if(![self isValidSession:session]) {
        return;
    }
    if(error) {
        [_delegate receivedFailureforTask:task];
    }
}

#pragma mark NSURLDataTask Delegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLCredential* credential = [[OEXConfig sharedConfig] URLCredentialForHost:challenge.protectionSpace.host];
    if(credential != nil) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
    else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)    URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask
    didReceiveResponse:(NSURLResponse*)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    if(![self isValidSession:session]) {
        return;
    }

    //Status
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = (int)[httpResponse statusCode];
    if(responseStatusCode != 200) {
        //ELog(@"Data Task failed for request [%@], Error [%d]", dataTask.taskDescription, responseStatusCode);
        [_delegate receivedFailureforTask:dataTask];
        return;
    }

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask
    didReceiveData:(NSData*)data {
    if(![self isValidSession:session]) {
        return;
    }

    //ELog(@"NSURLDataTask didReceiveData");
    [_delegate receivedData:data forTask:dataTask];
}

- (void)       URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask
    didBecomeDownloadTask:(NSURLSessionDownloadTask*)downloadTask {
    //ELog(@"URLSession : didBecomeDownloadTask");
}

- (void)   URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask
    willCacheResponse:(NSCachedURLResponse*)proposedResponse
    completionHandler:(void (^)(NSCachedURLResponse* cachedResponse))completionHandler {
    //ELog(@"URLSession : willCacheResponse");
}

- (void)            URLSession:(NSURLSession*)session
                          task:(NSURLSessionTask*)task
    willPerformHTTPRedirection:(NSHTTPURLResponse*)redirectResponse
                    newRequest:(NSURLRequest*)request
             completionHandler:(void (^)(NSURLRequest*))completionHandler {
    if(![self isValidSession:session]) {
        return;
    }

    NSMutableURLRequest* mutablerequest = [request mutableCopy];
    NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
    [mutablerequest setValue:authValue forHTTPHeaderField:@"Authorization"];

    completionHandler([mutablerequest copy]);
}

- (void)invokeBackgroundSessionCompletionHandlerForSession:(NSURLSession*)session {
}

- (void)callAuthorizedWebServiceWithURLPath:(NSString*)urlPath method:(NSString*)method body:(NSData*)body completionHandler:(void (^)(NSData* data, NSURLResponse* response, NSError* error))completionHandle {
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, urlPath]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:method];

    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody:body];

    NSURLSession* session = [self sessionForRequest:url];
    [[session dataTaskWithRequest:request completionHandler:completionHandle] resume];
}

@end
