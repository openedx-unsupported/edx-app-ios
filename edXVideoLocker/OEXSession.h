//
//  OEXSession.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXAccessToken;
@class OEXUserDetails;
@protocol OEXCredentialStorage;

@interface OEXSession : NSObject

+ (OEXSession*)sharedSession;
+ (void)setSharedSession:(OEXSession*)session;

- (id)initWithCredentialStore:(id <OEXCredentialStorage>)storage;

@property (readonly, nonatomic, strong) OEXAccessToken* token;
@property (readonly, nonatomic, strong) OEXUserDetails* currentUser;

- (void)loadTokenFromStore;
- (void)saveAccessToken:(OEXAccessToken*)token userDetails:(OEXUserDetails*)userDetails;
- (void)closeAndClearSession;

- (void)performMigrations;

@end
