//
//  OEXKeychainAccess.h
//  edXVideoLocker
//
//  Created by Abhradeep on 20/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXAccessToken, OEXUserDetails;

@protocol OEXCredentialStorage <NSObject>

@property (nonatomic, strong, readonly) OEXAccessToken* storedAccessToken;
@property (nonatomic, strong, readonly) OEXUserDetails* storedUserDetails;

- (void)saveAccessToken:(OEXAccessToken*)accessToken userDetails:(OEXUserDetails*)userDetails;
- (void)clear;

@end

@interface OEXKeychainAccess : NSObject <OEXCredentialStorage>

@end
