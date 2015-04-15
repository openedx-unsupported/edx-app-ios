//
//  OEXParsePushProviderTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <Parse/Parse.h>
#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

#import "NSArray+OEXFunctional.h"
#import "OEXCourse+OEXTestDataFactory.h"
#import "OEXInterface.h"
#import "OEXParsePushProvider.h"
#import "OEXUserDetails+OEXTestDataFactory.h"

@interface OEXMockPFInstallation : NSObject

@property (strong, nonatomic) NSString* deviceToken;
@property (copy, nonatomic) NSArray* channels;

@property (assign, nonatomic) BOOL saved;

@end

@implementation OEXMockPFInstallation

- (BFTask*)saveEventually {
    self.saved = YES;
    return nil;
}

@end

@interface OEXParsePushProviderTests : XCTestCase

@property (strong, nonatomic) OEXMockPFInstallation* installation;
@property (strong, nonatomic) id installationClassMock;
@property (strong, nonatomic) OEXParsePushProvider* provider;

@end

@implementation OEXParsePushProviderTests

- (void)setUp {
    self.installation = [[OEXMockPFInstallation alloc] init];
    self.installationClassMock = OCMStrictClassMock([PFInstallation class]);
    id stub = [self.installationClassMock stub];
    [stub currentInstallation];
    [stub andReturn:self.installation];
    
    self.provider = [[OEXParsePushProvider alloc] init];
}

- (void)tearDown {
    [self.installationClassMock stopMocking];
}

- (void)testMock {
    XCTAssertEqualObjects(self.installation, [PFInstallation currentInstallation]);
}

- (void)testRegistration {
    NSString* token = @"token";
    NSData* tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
    [self.provider didRegisterForRemoteNotificationsWithDeviceToken:tokenData];
    
    XCTAssertEqualObjects(self.installation.deviceToken, token);
    XCTAssertTrue(self.installation.saved);
}

- (NSArray*)changeCourses {
    NSArray* courses = [NSArray oex_arrayWithCount:4 generator:^id(NSUInteger index) {
        return [OEXCourse freshCourse];
    }];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:OEXCourseListChangedNotification
     object:nil
     userInfo:@{
                OEXCourseListKey : courses
                }];
    
    NSArray* expectedChannels = [courses oex_map:^id(OEXCourse* course) {
        return course.channel_id;
    }];
    
    return expectedChannels;
}

- (void)testCourseUpdateSession {
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    [self.provider sessionStartedWithUserDetails:userDetails];

    NSArray* expectedChannels = [self changeCourses];
    XCTAssertEqualObjects([NSSet setWithArray:self.installation.channels], [NSSet setWithArray:expectedChannels]);
    XCTAssertTrue(self.installation.saved);
}

- (void)testCourseUpdateNoSession {
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    [self.provider sessionStartedWithUserDetails:userDetails];
    [self changeCourses];
    
    self.installation.saved = NO;
    
    [self.provider sessionEnded];
    
    XCTAssertEqual(self.installation.channels.count, 0);
    XCTAssertTrue(self.installation.saved);
}

- (void)testSignOut {
    [self changeCourses];
}

@end
