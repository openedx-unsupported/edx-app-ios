//
//  OEXSession.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Fires when the user logs in or at launch if there is an already logged in user
extern NSString* const OEXSessionStartedNotification;
/// NSNotification userInfo key for OEXSessionStartedNotification. An OEXUserDetails
extern NSString* const OEXSessionStartedUserDetailsKey;

/// Fires when a user logs out
extern NSString* const OEXSessionEndedNotification;

@class OEXAccessToken;
@class OEXUserDetails;
@protocol OEXCredentialStorage;

@interface OEXSession : NSObject

+ (nullable OEXSession*)sharedSession;
+ (void)setSharedSession:(OEXSession*)session;

- (id)initWithCredentialStore:(id <OEXCredentialStorage>)storage;

@property (readonly, nonatomic, strong, nullable) OEXAccessToken* token;
@property (readonly, nonatomic, strong, nullable) OEXUserDetails* currentUser;

- (void)loadTokenFromStore;
- (void)saveAccessToken:(OEXAccessToken*)token userDetails:(OEXUserDetails*)userDetails;
- (void)closeAndClearSession;
- (void)removeAllWebData;

- (void)performMigrations;

@end

@interface OEXSession (Testing)

- (void)t_setClearedURLCache;

@end

@protocol OEXSessionProvider <NSObject>

@property (readonly, nonatomic) OEXSession* session;

@end

NS_ASSUME_NONNULL_END
