//
//  OEXSession.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXAccessToken.h"
#import "OEXUserDetails.h"
@interface OEXSession : NSObject
@property(readonly, copy) OEXAccessToken* edxToken;
@property(readonly, copy) OEXUserDetails* currentUser;

+ (OEXSession*)activeSession;

- (void)closeAndClearSession;

+ (OEXSession*)createSessionWithAccessToken:(OEXAccessToken*)accessToken andUserDetails:(OEXUserDetails*)userDetails;

+ (void)migrateToKeychainIfNecessary;

@end
