//
//  edXNetworkInterface.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkManager.h"

@protocol EdXNetworkInterfaceDelegate <NSObject>

//Foreground Calls
- (void)returnedData:(NSData *)data forType:(NSString *)URLString;
- (void)returnedFaliureForType:(NSString *)URLString;

//Background Calls
- (void)didAddDownloadForURLString:(NSString *)URLString;
- (void)didRejectDownloadForURLString:(NSString *)URLString;

@end

@interface edXNetworkInterface : NSObject <NetworkManagerDelegate>

@property (nonatomic, strong) id <EdXNetworkInterfaceDelegate> delegate;

#pragma mark Public

- (void)callRequestString:(NSString *)requestString;
- (NSString *)descriptionForURLString:(NSString *)URLString;
- (void)downloadWithURLString:(NSString *)URLString;
- (NSString *)URLStringForType:(NSString *)type;
- (void)cancelDownloadForURL:(NSString *)URLString
           completionHandler:(void (^)(BOOL success))completionHandler;
+(void)clearNetworkSession;

- (void)activate;
- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler;

@end
