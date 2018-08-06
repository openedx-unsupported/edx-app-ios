//
//  OEXSession.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXSession.h"

#import "OEXAccessToken.h"
#import "OEXFBSocial.h"
#import "OEXGoogleSocial.h"
#import "OEXFileUtility.h"
#import "OEXPersistentCredentialStorage.h"
#import "OEXUserDetails.h"
#import <WebKit/WebKit.h>


NSString* const OEXSessionStartedNotification = @"OEXSessionStartedNotification";
NSString* const OEXSessionStartedUserDetailsKey = @"OEXSessionStartedUserDetailsKey";
NSString* const OEXSessionEndedNotification = @"OEXSessionEndedNotification";

static OEXSession* sSharedSession = nil;

// These are deprecated, but still necessary for migration
NSString* const oauthTokenKey = @"oauth_token";
NSString* const authTokenType = @"token_type";
NSString* const authTokenResponse = @"authTokenResponse";
NSString* const loggedInUser = @"loginUserDetails";

static NSString* OEXSessionClearedCache = @"OEXSessionClearedCache";

@interface OEXSession ()

@property (nonatomic, strong) OEXAccessToken* token;
@property (nonatomic, strong) OEXUserDetails* currentUser;
@property (nonatomic, strong) id <OEXCredentialStorage> credentialStore;

@end

@implementation OEXSession

+ (void)setSharedSession:(OEXSession *)session {
    sSharedSession = session;
}

+ (OEXSession*)sharedSession {
    return sSharedSession;
}

- (id)initWithCredentialStore:(id<OEXCredentialStorage>)storage {
    if(self = [super init]) {
        self.credentialStore = storage;
    }
    return self;
}

- (id)init {
    return [self initWithCredentialStore:[[OEXPersistentCredentialStorage alloc] init]];
}

- (void)saveAccessToken:(OEXAccessToken*)token userDetails:(OEXUserDetails*)userDetails {
    [self.credentialStore clear];
    [self.credentialStore saveAccessToken:token userDetails:userDetails];

    self.token = token;
    self.currentUser = userDetails;
    if(token != nil && userDetails != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:OEXSessionStartedNotification object:nil userInfo:@{OEXSessionStartedUserDetailsKey : userDetails}];
    }
}

- (void)loadTokenFromStore {
    OEXAccessToken* tokenData = self.credentialStore.storedAccessToken;
    OEXUserDetails* userDetails = self.credentialStore.storedUserDetails;

    if(tokenData && userDetails) {
        self.token = tokenData;
        self.currentUser = userDetails;
        [[NSNotificationCenter defaultCenter] postNotificationName:OEXSessionStartedNotification object:nil userInfo:@{OEXSessionStartedUserDetailsKey : userDetails}];
    }
    else {
        [self.credentialStore clear];
    }
}

- (void)closeAndClearSession {
    [self.credentialStore clear];
    self.currentUser = nil;
    self.token = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OEXSessionEndedNotification object:nil];
}

- (void)removeAllWebData {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [WKWebsiteDataStore.defaultDataStore removeDataOfTypes:WKWebsiteDataStore.allWebsiteDataTypes modifiedSince:date completionHandler:^{}];
}

#pragma mark Migrations

// See https://openedx.atlassian.net/browse/MA-791
// Probably safe to delete this around November, 2015
- (void)clearURLCacheIfNecessary {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:OEXSessionClearedCache]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:OEXSessionClearedCache];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
}

- (void)migrateToKeychainIfNecessary {
    // Remove sensitive data from NSUserDefaults if any

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    if([userDefaults objectForKey:loggedInUser] && [userDefaults objectForKey:authTokenResponse]) {
        OEXUserDetails* userDetails = [[OEXUserDetails alloc] initWithUserDictionary:[userDefaults objectForKey:loggedInUser]];
        OEXAccessToken* token = [[OEXAccessToken alloc] initWithTokenDetails:[userDefaults objectForKey:authTokenResponse]];
        [self.credentialStore saveAccessToken:token userDetails:userDetails];
        [self loadTokenFromStore];
    }

    [userDefaults removeObjectForKey:loggedInUser];
    [userDefaults removeObjectForKey:authTokenResponse];
    [userDefaults removeObjectForKey:oauthTokenKey];
    [userDefaults synchronize];
}

- (void)clearDeprecatedSessionTokenIfNecessary {
    if(self.token.isDeprecatedSessionToken) {
        [self closeAndClearSession];
    }
}

- (void)performMigrations {
    [self migrateToKeychainIfNecessary];
    [self clearDeprecatedSessionTokenIfNecessary];
    [self clearURLCacheIfNecessary];
    
    if(self.currentUser != nil) {
        NSString* userDir = [OEXFileUtility pathForUserNameCreatingIfNecessary:self.currentUser.username];
        BOOL hasUserDir = [[NSFileManager defaultManager] fileExistsAtPath:userDir];
        if(!hasUserDir) {
            [[OEXSession sharedSession] closeAndClearSession];
        }
    }

}

@end

@implementation OEXSession (Testing)

- (void)t_setClearedURLCache {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:OEXSessionClearedCache];
}

@end
