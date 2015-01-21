//
//  OEXKeychainAccess.h
//  edXVideoLocker
//
//  Created by Abhradeep on 20/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXAcessToken;

@interface OEXKeychainAccess : NSObject

@property (nonatomic, strong, readonly) OEXAcessToken *storedAccessToken;
@property (nonatomic, strong, readonly) NSDictionary *storedUserDetails;

+ (instancetype)sharedKeychainAccess;

-(void)startSessionWithAccessToken:(OEXAcessToken *)accessToken userDetails:(NSDictionary *)userDetails;
-(void)endSession;

@end
