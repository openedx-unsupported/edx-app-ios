//
//  OEXNetworkInterface.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

#import "OEXNetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OEXNetworkInterfaceDelegate <NSObject>

//Foreground Calls
- (void)returnedData:(NSData*)data forType:(NSString*)URLString;
- (void)returnedFailureForType:(NSString*)URLString;

//Background Calls
- (void)didAddDownloadForURLString:(NSString*)URLString;
- (void)didRejectDownloadForURLString:(NSString*)URLString;

@end

@interface OEXNetworkInterface : NSObject <OEXNetworkManagerDelegate>

@property (nonatomic, strong) id <OEXNetworkInterfaceDelegate> delegate;

#pragma mark Public

- (void)callRequestString:(NSString*)requestString;
- (NSString*)descriptionForURLString:(NSString*)URLString;
- (void)downloadWithURLString:(NSString*)URLString;
- (NSString*)URLStringForType:(NSString*)type;
+ (void)clearNetworkSession;

- (void)activate;
- (void)invalidateNetworkManager;

@end

NS_ASSUME_NONNULL_END
