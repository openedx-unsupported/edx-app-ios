//
//  NetworkManager.h
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 05/05/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OEXNetworkManagerDelegate <NSObject>

//Foreground Calls
- (void)receivedData:(NSData *)data forTask:(NSURLSessionTask *)task;
- (void)receivedFaliureforTask:(NSURLSessionTask *)task;

//Background Calls
- (void)downloadAlreadyExistsForURL:(NSURL *)url;
- (void)downloadAddedForURL:(NSURL *)url;

@end

@interface OEXNetworkManager : NSObject <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *foregroundSession;
@property (nonatomic, strong) NSURLSession *backgroundSession;
@property (nonatomic, strong) id <OEXNetworkManagerDelegate> delegate;

+ (id)sharedManager;

#pragma mark Background requests

- (void)downloadInBackground:(NSURL *)url;
- (void)cancelDownloadForURL:(NSURL *)url
           completionHandler:(void (^)(BOOL success))completionHandler;
+(void)clearNetworkManager;
- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler;
- (void)activate;

@end
