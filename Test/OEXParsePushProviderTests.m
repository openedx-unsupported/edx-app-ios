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
#import "OEXMockUserDefaults.h"
#import "OEXPushSettingsManager.h"
#import "OEXParsePushProvider.h"
#import "OEXUserDetails+OEXTestDataFactory.h"

@interface OEXMockPFInstallation : NSObject

@property (strong, nonatomic) NSString* deviceToken;
@property (copy, nonatomic) NSArray* channels;

@property (assign, nonatomic) BOOL saved;

@end

@implementation OEXMockPFInstallation

- (NSString*)tokenStringWithData:(NSData*)deviceToken {
    NSCharacterSet* allowedCharacters = [NSCharacterSet alphanumericCharacterSet];
    return [deviceToken.description stringByTrimmingCharactersInSet:[allowedCharacters invertedSet]];
}

- (void)setDeviceTokenFromData:(NSData *)deviceToken {
    self.deviceToken = [self tokenStringWithData:deviceToken];
}

- (BFTask*)saveEventually {
    self.saved = YES;
    return nil;
}

@end

@interface OEXParsePushProviderTests : XCTestCase

@property (strong, nonatomic) OEXMockPFInstallation* installation;
@property (strong, nonatomic) OCMockObject* defaultsClassMock;
@property (strong, nonatomic) OCMockObject* installationClassMock;
@property (strong, nonatomic) OEXParsePushProvider* provider;

@end

@implementation OEXParsePushProviderTests

- (void)setUp {
    self.installation = [[OEXMockPFInstallation alloc] init];
    self.installationClassMock = OCMStrictClassMock([PFInstallation class]);
    id installationStub = [self.installationClassMock stub];
    [installationStub currentInstallation];
    [installationStub andReturn:self.installation];
    
    OEXMockUserDefaults* defaults = [[OEXMockUserDefaults alloc] init];
    OCMockObject* defaultsClassMock = OCMStrictClassMock([NSUserDefaults class]);
    id defaultsStub = [defaultsClassMock stub];
    [defaultsStub standardUserDefaults];
    [defaultsStub andReturn:defaults];
    
    self.provider = [[OEXParsePushProvider alloc] init];
}

- (void)tearDown {
    [self.installationClassMock stopMocking];
    [self.defaultsClassMock stopMocking];
    self.provider = nil;
}

- (void)testMock {
    XCTAssertEqualObjects(self.installation, [PFInstallation currentInstallation]);
}

- (void)testRegistration {
    char tokenBytes[] = {0x12, 0x34, 0x56, 0x78};
    NSData* tokenData = [NSData dataWithBytes:tokenBytes length:4];
    [self.provider didRegisterForRemoteNotificationsWithDeviceToken:tokenData];
    
    XCTAssertEqualObjects(self.installation.deviceToken, @"12345678");
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
    
    return courses;
}

- (void)testCourseUpdateSession {
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    OEXPushSettingsManager* settingsManager = [[OEXPushSettingsManager alloc] init];
    [self.provider sessionStartedWithUserDetails:userDetails settingsManager:settingsManager];

    NSArray* expectedChannels = [[self changeCourses] oex_map:^id(OEXCourse* course) {
        return course.subscription_id;
    }];
    XCTAssertEqualObjects([NSSet setWithArray:self.installation.channels], [NSSet setWithArray:expectedChannels]);
    XCTAssertTrue(self.installation.saved);
}

- (void)testCourseUpdateNoSession {
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    OEXPushSettingsManager* settingsManager = [[OEXPushSettingsManager alloc] init];
    [self.provider sessionStartedWithUserDetails:userDetails settingsManager:settingsManager];
    [self changeCourses];
    
    self.installation.saved = NO;
    
    [self.provider sessionEnded];
    
    XCTAssertEqual(self.installation.channels.count, 0);
    XCTAssertTrue(self.installation.saved);
}

- (void)testDisabledCourseFiltered {
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    OEXPushSettingsManager* settingsManager = [[OEXPushSettingsManager alloc] init];
    [self.provider sessionStartedWithUserDetails:userDetails settingsManager:settingsManager];
    NSArray* courses = [self changeCourses];
    
    OEXCourse* course = courses.firstObject;
    XCTAssertNotNil(course.subscription_id);
    
    [settingsManager setPushDisabled:YES forCourseID:course.course_id];
    
    XCTAssertFalse([self.installation.channels containsObject:course.subscription_id]);
    XCTAssertEqual(self.installation.channels.count + 1, courses.count);
}

- (void)testSignOut {
    OEXUserDetails* userDetails = [OEXUserDetails freshUser];
    OEXPushSettingsManager* settingsManager = [[OEXPushSettingsManager alloc] init];
    [self.provider sessionStartedWithUserDetails:userDetails settingsManager:settingsManager];
    [self.provider didRegisterForRemoteNotificationsWithDeviceToken:[@"token" dataUsingEncoding:NSUTF8StringEncoding]];
    [self changeCourses];
    
    XCTAssertNotNil(self.installation.deviceToken);
    XCTAssertGreaterThan(self.installation.channels.count, 0);
    
    [self.provider sessionEnded];
    
    XCTAssertEqual(self.installation.deviceToken.length, 0);
    XCTAssertNotNil(self.installation.deviceToken, @"Parse can't save nil objects");
    XCTAssertEqual(self.installation.channels.count, 0);
}

@end
