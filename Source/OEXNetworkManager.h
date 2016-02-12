//
//  NetworkManager.h
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 05/05/14.
//  Copyright (c) 2014-2016 edX, Inc. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

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

@property (nonatomic, strong, nullable) NSURLSession* foregroundSession;
@property (nonatomic, strong, nullable) NSURLSession* backgroundSession;
@property (nonatomic, strong) id <OEXNetworkManagerDelegate> delegate;

+ (id)sharedManager;

#pragma mark Background requests

- (void)downloadInBackground:(NSURL*)url;
+ (void)clearNetworkManager;
- (void)invalidateNetworkManager;
- (void)activate;

- (void)callAuthorizedWebServiceWithURLPath:(NSString*)urlPath method:(NSString*)method body:(NSData*)body completionHandler:(void (^)(NSData* data, NSURLResponse* response, NSError* error))completionHandle;

@end

NS_ASSUME_NONNULL_END
