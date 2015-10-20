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
- (void)receivedData:(NSData*)data forTask:(NSURLSessionTask*)task;
- (void)receivedFailureforTask:(NSURLSessionTask*)task;

//Background Calls
- (void)downloadAlreadyExistsForURL:(NSURL*)url;
- (void)downloadAddedForURL:(NSURL*)url;

@end

/// THIS CLASS IS DEPRECATED
/// You should use the swift based NetworkManager
@interface OEXNetworkManager : NSObject <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession* foregroundSession;
@property (nonatomic, strong) NSURLSession* backgroundSession;
@property (nonatomic, strong) id <OEXNetworkManagerDelegate> delegate;

+ (id)sharedManager;

#pragma mark Background requests

- (void)downloadInBackground:(NSURL*)url;
+ (void)clearNetworkManager;
- (void)invalidateNetworkManager;
- (void)activate;

- (void)callAuthorizedWebServiceWithURLPath:(NSString*)urlPath method:(NSString*)method body:(NSData*)body completionHandler:(void (^)(NSData* data, NSURLResponse* response, NSError* error))completionHandle;

@end
