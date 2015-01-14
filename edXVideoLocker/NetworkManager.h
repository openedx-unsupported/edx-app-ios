//
//  NetworkManager.h
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 05/05/14.
//  Copyright (c) 2014 Clarice Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkConstants.h"

@protocol NetworkManagerDelegate <NSObject>

//Foreground Calls
- (void)receivedData:(NSData *)data forTask:(NSURLSessionTask *)task;
- (void)receivedFaliureforTask:(NSURLSessionTask *)task;

//Background Calls
- (void)downloadAlreadyExistsForURL:(NSURL *)url;
- (void)downloadAddedForURL:(NSURL *)url;

@end

@interface NetworkManager : NSObject <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *foregroundSession;
@property (nonatomic, strong) NSURLSession *backgroundSession;
@property (nonatomic, strong) id <NetworkManagerDelegate> delegate;

+ (id)sharedManager;

#pragma mark Background requests

- (void)downloadInBackground:(NSURL *)url;
- (void)cancelDownloadForURL:(NSURL *)url
           completionHandler:(void (^)(BOOL success))completionHandler;
+(void)clearNetworkManager;
- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler;
- (void)activate;

@end
