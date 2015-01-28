//
//  OEXSessionTests.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OEXUserDetails.h"
#import "OEXSession.h"
@interface OEXSessionTests : XCTestCase

@end

@implementation OEXSessionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[OEXSession activeSession] closeAndClearSession];
    [super tearDown];
}

-(void)testCreateSession{
    
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
    
    OEXAccessToken *edxToken=[[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user=[[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    OEXSession *session=[OEXSession createSessionWithAccessToken:edxToken andUserDetails:user];
    
    XCTAssertNotNil(session,@"Session should not be nil");
    
    XCTAssertNotNil(session.currentUser.username, @"Current User for Sesion Should not be nil.");
    
    XCTAssertNotNil(session.edxToken.accessToken, @"Token For session should not be nil.");
    
    
    
}


-(void)testCloseAndClearSession{
    
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
    
    OEXAccessToken *edxToken=[[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user=[[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    OEXSession *session=[OEXSession createSessionWithAccessToken:edxToken andUserDetails:user];
    
    XCTAssertNotNil(session,@"Session should not be nil");
    
    [session closeAndClearSession];
    
    XCTAssertNil([OEXSession activeSession],@"Active Session should be nil");

}

-(void)testCreateTokenWithInvalidUserData{
    
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
    
    OEXAccessToken *edxToken=[[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user=[[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    OEXSession *session=[OEXSession createSessionWithAccessToken:edxToken andUserDetails:user];
    
    XCTAssertNil(session,@"Session should not create for invalid user data ");
    
    
}

-(void)testCreateSessionWithInvalidTokenData{
    
    NSDictionary *userDetails=@{@"email":@"test@example.com",
                                @"username":@"testUser",
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
    
    OEXAccessToken *edxToken=[[OEXAccessToken alloc] initWithTokenDetails:tokenDetails];
    OEXUserDetails *user=[[OEXUserDetails alloc] initWithUserDictionary:userDetails];
    OEXSession *session=[OEXSession createSessionWithAccessToken:edxToken andUserDetails:user];
    XCTAssertNil(session,@"Session should not create for invalid token data");
    
}


-(void)testMigrateToKeychain{
   
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
    
    [userDefaults synchronize];
    
    [OEXSession migrateToKeychainIfNecessary];
    
    XCTAssertNil([userDefaults objectForKey:@"loginUserDetails"],@"User details should be removed from user defaults");
    
    XCTAssertNil([userDefaults objectForKey:@"authTokenResponse"],@"User authtoken response should be removed from user defaults");
    
    XCTAssertNil([userDefaults objectForKey:@"oauth_token"],@"User oauth_token should be removed from user defaults");
    
    XCTAssertNotNil([OEXSession activeSession],@"Active session should not be nil");
    
}

@end
