//
//  OEXSessionTests.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXAccessToken.h"
#import "OEXMockCredentialStorage.h"
#import "OEXMockUserDefaults.h"
#import "OEXRemovable.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"
#import "OEXUserDetails+OEXTestDataFactory.h"

@interface OEXMockURLCache : NSObject

@property (assign, nonatomic) BOOL flushed;

@end

@implementation OEXMockURLCache

- (void)removeAllCachedResponses {
    self.flushed = YES;
}

@end

@interface OEXSessionTests : XCTestCase

@property (strong, nonatomic) OEXMockCredentialStorage* credentialStore;
@property (strong, nonatomic) id cacheClassMock;

@property (strong, nonatomic) id <OEXRemovable> defaultsMockRemover;
@property (strong, nonatomic) OEXMockUserDefaults* mockUserDefaults;

@property (strong, nonatomic) OEXMockURLCache* mockURLCache;

@end

@implementation OEXSessionTests

- (void)setUp {
    [super setUp];
    self.credentialStore = [[OEXMockCredentialStorage alloc] init];
    
    self.mockUserDefaults = [[OEXMockUserDefaults alloc] init];
    self.defaultsMockRemover = [self.mockUserDefaults installAsStandardUserDefaults];
    
    self.cacheClassMock = OCMStrictClassMock([NSURLCache class]);
    self.mockURLCache = [[OEXMockURLCache alloc] init];
    
    id stub = [self.cacheClassMock stub];
    [stub sharedURLCache];
    [stub andReturn:self.mockURLCache];
}

- (void)tearDown {
    [super tearDown];
    [self.cacheClassMock stopMocking];
    [self.defaultsMockRemover remove];
}

- (void)testLoadCredentialsFromStorage {
    NSDictionary *userDetails =
    @{
      @"email":@"test@example.com",
      @"username":@"testUser",
      @"course_enrollments":@"http://www.edx.org/enrollments.com",
      @"name":@"testuser",
      @"id":@"test@example.com",
      @"url":@"test@example.com"
      };
    
    NSDictionary *tokenDetails =
    @{@"access_token":@"test@example.com",
      @"token_type":@"testUser",
      @"expires_in":@"http://www.edx.org/enrollments.com",
      @"scope":@"testuser"
      };
    
    OEXAccessToken *accessToken = [[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user = [[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    [self.credentialStore saveAccessToken:accessToken userDetails:user];
    
    OEXSession *session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session loadTokenFromStore];
    
    XCTAssertNotNil(session.currentUser.username, @"Current User for Sesion Should not be nil.");
    XCTAssertNotNil(session.token.accessToken, @"Token For session should not be nil.");
}


- (void)testCloseAndClearSession{
    
    NSDictionary *userDetails=@{@"email":@"test@example.com",
                                @"username":@"testUser",
                                @"course_enrollments":@"http://www.edx.org/enrollments.com",
                                @"name":@"testuser",
                                @"id":@"test@example.com",
                                @"url":@"test@example.com"
                                };
    
    NSDictionary *tokenDetails=@{@"access_token":@"csdnsjnsjdkvdkfbv",
                                 @"token_type":@"Bearer",
                                 @"expires_in":@"12324",
                                 @"scope":@""
                                 };
    
    OEXAccessToken *token = [[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user = [[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session saveAccessToken:token userDetails:user];
    
    XCTAssertNotNil(session.token,@"Session should not be nil");
    XCTAssertNotNil(session.currentUser,@"Current user should not be nil");
    
    [session closeAndClearSession];
    
    XCTAssertNil(session.token, @"Active Session should be nil");
    XCTAssertNil(session.currentUser, @"Active Session should be nil");
    
}

- (void)testCreateSessionWithInvalidUserData {
    
    NSDictionary *userDetails=@{@"email":@"",
                                @"username":@"",
                                @"course_enrollments":@"http://www.edx.org/enrollments.com",
                                @"name":@"testuser",
                                @"id":@"test@example.com",
                                @"url":@"test@example.com"
                                };
    
    NSDictionary *tokenDetails=@{@"access_token":@"csdnsjnsjdkvdkfbv",
                                 @"token_type":@"Bearer",
                                 @"expires_in":@"12324",
                                 @"scope":@""
                                 };
    
    OEXAccessToken *edxToken = [[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user = [[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    
    [self.credentialStore saveAccessToken:edxToken userDetails:user];
    
    OEXSession *session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    
    XCTAssertNil(session.token);
    XCTAssertNil(session.currentUser);
    
}

- (void)testCreateSessionWithInvalidTokenData{
    
    NSDictionary *userDetails=@{@"email":@"test@example.com",
                                @"course_enrollments":@"http://www.edx.org/enrollments.com",
                                @"name":@"testuser",
                                @"id":@"test@example.com",
                                @"url":@"test@example.com"
                                };
    
    NSDictionary *tokenDetails=@{@"access_token":@"",
                                 @"token_type":@"",
                                 @"expires_in":@"12324",
                                 @"scope":@""
                                 };
    
    OEXAccessToken *edxToken = [[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user = [[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    [self.credentialStore saveAccessToken:edxToken userDetails:user];
    
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    
    XCTAssertNil(session.token);
    XCTAssertNil(session.currentUser);
    
}

- (void)testMigrationClearSessionStorage {
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    token.accessToken = @"some token";
    token.expiryDuration = @36000;
    token.scope = @"sample scope";
    
    OEXUserDetails* userDetails = [[OEXUserDetails alloc] init];
    
    [self.credentialStore saveAccessToken:token userDetails:userDetails];
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session loadTokenFromStore];
    XCTAssertNotNil(session.token);
    XCTAssertNotNil(session.currentUser);
    
    // If a user was using a session token for authentication we should log them out
    [session performMigrations];
    XCTAssertNil(session.token);
    XCTAssertNil(session.currentUser);
}

- (void)testMigrationUserDefaultsToKeychain {
    
    NSDictionary *userDetails=@{@"email":@"test@example.com",
                                @"username":@"testUser",
                                @"course_enrollments":@"http://www.edx.org/enrollments.com",
                                @"name":@"testuser",
                                @"id":@"test@example.com",
                                @"url":@"test@example.com"
                                };
    
    NSDictionary *tokenDetails=@{@"access_token":@"test@example.com",
                                 @"token_type":@"testUser",
                                 @"expires_in":@"http://www.edx.org/enrollments.com",
                                 @"scope":@"testuser"
                                 };
    
    
    [self.mockUserDefaults setObject:userDetails forKey:@"loginUserDetails"];
    [self.mockUserDefaults setObject:tokenDetails forKey:@"authTokenResponse"];
    [self.mockUserDefaults setObject:@"sfsdjkfskdhfsdskdjf" forKey:@"oauth_token"];
    
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session performMigrations];
    
    XCTAssertNil([self.mockUserDefaults objectForKey:@"loginUserDetails"],@"User details should be removed from user defaults");
    
    XCTAssertNil([self.mockUserDefaults objectForKey:@"authTokenResponse"],@"User authtoken response should be removed from user defaults");
    
    XCTAssertNil([self.mockUserDefaults objectForKey:@"oauth_token"],@"User oauth_token should be removed from user defaults");
    
    XCTAssertNotNil(session.token, @"Active session should not be nil");
    XCTAssertNotNil(session.currentUser, @"Active session should not be nil");
}

- (void)testMigrationClearCache {
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session performMigrations];
    
    XCTAssertTrue(self.mockURLCache.flushed);
}

- (void)testMigrationClearCacheAlreadyPerformed {
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session t_setClearedURLCache];
    XCTAssertFalse(self.mockURLCache.flushed);
}

- (void)testStartedNotificationFiresWithInitialCredentials {
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    [self.credentialStore saveAccessToken:token userDetails:userDetails];
    
    __block BOOL fired = NO;
    [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionStartedNotification action:^(NSNotification *notification, id observer, id<OEXRemovable> removable) {
        XCTAssertEqualObjects(notification.userInfo[OEXSessionStartedUserDetailsKey], userDetails);
        fired = YES;
        [removable remove];
    }];
    
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session loadTokenFromStore];

    XCTAssertNotNil(session.token);
    XCTAssertTrue(fired);
}

- (void)testStartedNotificationFiresAfterSave {
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    __block BOOL fired = NO;
    [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionStartedNotification action:^(NSNotification *notification, id observer, id<OEXRemovable> removable) {
        XCTAssertEqualObjects(notification.userInfo[OEXSessionStartedUserDetailsKey], userDetails);
        fired = YES;
        [removable remove];
    }];
    [session saveAccessToken:token userDetails:userDetails];
    
    XCTAssertTrue(fired);
}

- (void)testEndedNotificationFires {
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    [session saveAccessToken:token userDetails:userDetails];
    
    __block BOOL fired = NO;
    [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionEndedNotification action:^(NSNotification *notification, id observer, id<OEXRemovable> removable) {
        fired = YES;
        [removable remove];
    }];
    [session closeAndClearSession];
    
    XCTAssertTrue(fired);
}

@end
