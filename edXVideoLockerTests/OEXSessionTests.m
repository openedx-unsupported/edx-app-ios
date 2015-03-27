//
//  OEXSessionTests.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXAccessToken.h"
#import "OEXKeychainAccess.h"
#import "OEXUserDetails.h"
#import "OEXSession.h"

// Pretend keychain that doesn't persist across runs
@interface OEXMockKeychainAccess : NSObject <OEXCredentialStorage>

@property (strong, nonatomic) OEXAccessToken* storedAccessToken;
@property (strong, nonatomic) OEXUserDetails* storedUserDetails;

@end

@implementation OEXMockKeychainAccess

- (void)saveAccessToken:(OEXAccessToken *)accessToken userDetails:(OEXUserDetails *)userDetails {
    self.storedAccessToken = accessToken;
    self.storedUserDetails = userDetails;
}

- (void)clear {
    self.storedAccessToken = nil;
    self.storedUserDetails = nil;
}

@end

@interface OEXSessionTests : XCTestCase

@property (strong, nonatomic) OEXMockKeychainAccess* credentialStore;

@end

@implementation OEXSessionTests

- (void)setUp {
    self.credentialStore = [[OEXMockKeychainAccess alloc] init];
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
    
    XCTAssertNil([OEXSession sharedSession].token, @"Active Session should be nil");
    XCTAssertNil([OEXSession sharedSession].currentUser, @"Active Session should be nil");
    
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
    token.expiryDate = [NSDate date];
    token.scope = @"sample scope";
    
    OEXUserDetails* userDetails = [[OEXUserDetails alloc] init];
    
    [self.credentialStore saveAccessToken:token userDetails:userDetails];
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
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
    
    
    NSUserDefaults *userDefaults=[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:userDetails forKey:@"loginUserDetails"];
    [userDefaults setObject:tokenDetails forKey:@"authTokenResponse"];
    [userDefaults setObject:@"sfsdjkfskdhfsdskdjf" forKey:@"oauth_token"];
    
    OEXSession* session = [[OEXSession alloc] initWithCredentialStore:self.credentialStore];
    [session performMigrations];
    
    XCTAssertNil([userDefaults objectForKey:@"loginUserDetails"],@"User details should be removed from user defaults");
    
    XCTAssertNil([userDefaults objectForKey:@"authTokenResponse"],@"User authtoken response should be removed from user defaults");
    
    XCTAssertNil([userDefaults objectForKey:@"oauth_token"],@"User oauth_token should be removed from user defaults");
    
    XCTAssertNotNil(session.token, @"Active session should not be nil");
    XCTAssertNotNil(session.currentUser, @"Active session should not be nil");
    
}

@end
