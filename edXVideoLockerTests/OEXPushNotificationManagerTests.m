//
//  OEXPushNotificationManagerTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OEXAccessToken.h"
#import "OEXMockKeychainAccess.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushProvider.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"

@interface OEXPushNotificationManagerTests : XCTestCase

@property (strong, nonatomic) OEXPushNotificationManager* manager;
@property (strong, nonatomic) OEXSession* session;
@property (strong, nonatomic) id provider;
@property (assign, nonatomic) BOOL registered;

@end

@implementation OEXPushNotificationManagerTests

- (void)setUp {
    __weak __typeof(self) weakSelf = self;
    self.manager = [[OEXPushNotificationManager alloc] initWithRegistrationAction:^{
        weakSelf.registered = YES;
    }];
    self.session = [[OEXSession alloc] initWithCredentialStore:[[OEXMockKeychainAccess alloc] init]];
    self.provider = OCMStrictProtocolMock(@protocol(OEXPushProvider));
}

- (void)tearDown {
    self.manager = nil;
    self.session = nil;
    self.provider = nil;
}

- (void)testProviderRoutingNotification {
    [self.manager addProvider:self.provider withSession:self.session];
    
    NSDictionary* userInfo = @{@"thing" : @"happened"};
    [[self.provider expect] didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    [self.manager didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    OCMVerifyAll(self.provider);
}

- (void)testProviderRoutingRegistrationSuccess {
    [self.manager addProvider:self.provider withSession:self.session];
    
    NSData* token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];
    [[self.provider expect] didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    [self.manager didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    OCMVerifyAll(self.provider);
    XCTAssertFalse(self.registered);
}

- (void)testProviderRoutingRegistrationFailure {
    [self.manager addProvider:self.provider withSession:self.session];
    
    NSError* error = [[NSError alloc] initWithDomain:@"error" code:2 userInfo:@{}];
    [[self.provider expect] didFailToRegisterForRemoteNotificationsWithError:error];
    
    [self.manager didFailToRegisterForRemoteNotificationsWithError:error];
    
    OCMVerifyAll(self.provider);
    XCTAssertFalse(self.registered);
}


- (void)testProviderSessionStartsBeforeSetup {
    
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    OEXUserDetails* userDetails = [[OEXUserDetails alloc] init];
    [self.session saveAccessToken:token userDetails:userDetails];
    
    [[self.provider expect] sessionStartedWithUserDetails:userDetails];
    
    [self.manager addProvider:self.provider withSession:self.session];
    
    OCMVerifyAll(self.provider);
    XCTAssertTrue(self.registered);
}

- (void)testProviderSessionStartsAfterSetup {
    [self.manager addProvider:self.provider withSession:self.session];
    
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    OEXUserDetails* userDetails = [[OEXUserDetails alloc] init];
    
    [[self.provider expect] sessionStartedWithUserDetails:userDetails];
    
    [self.session saveAccessToken:token userDetails:userDetails];
    
    OCMVerifyAll(self.provider);
    XCTAssertTrue(self.registered);
}

- (void)testProviderSessionEnds {
    [self.manager addProvider:self.provider withSession:self.session];
    
    [[self.provider expect] sessionEnded];
    
    [self.session closeAndClearSession];
    
    OCMVerifyAll(self.provider);
}

@end
