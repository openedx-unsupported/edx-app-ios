//
//  OEXKeychainAccess.h
//  edXVideoLocker
//
//  Created by Abhradeep on 20/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXAccessToken;

@interface OEXKeychainAccess : NSObject

@property (nonatomic, strong, readonly) OEXAccessToken *storedAccessToken;
@property (nonatomic, strong, readonly) NSDictionary *storedUserDetails;

+ (instancetype)sharedKeychainAccess;

-(void)startSessionWithAccessToken:(OEXAccessToken *)accessToken userDetails:(NSDictionary *)userDetails;
-(void)endSession;

@end
