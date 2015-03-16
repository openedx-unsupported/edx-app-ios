//
//  OEXKeychainAccess.h
//  edXVideoLocker
//
//  Created by Abhradeep on 20/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXAccessToken, OEXUserDetails;

@interface OEXKeychainAccess : NSObject

@property (nonatomic, strong, readonly) OEXAccessToken* storedAccessToken;
@property (nonatomic, strong, readonly) OEXUserDetails* storedUserDetails;

+ (instancetype)sharedKeychainAccess;

-(void)startSessionWithAccessToken:(OEXAccessToken*)accessToken userDetails:(OEXUserDetails*)userDetails;
-(void)endSession;

@end
