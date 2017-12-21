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
#import "OEXMockCredentialStorage.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushListener.h"
#import "OEXPushProvider.h"
#import "OEXPushSettingsManager.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"

@interface OEXMockApplicationNotifications : NSObject

@property (assign, nonatomic) BOOL registered;

@property(nonatomic) NSInteger applicationIconBadgeNumber;

@end

@implementation OEXMockApplicationNotifications

- (void)registerForRemoteNotifications {
    self.registered = true;
}

- (void)registerUserNotificationSettings:(UIUserNotificationSettings*)settings {
    // Do nothing
}

// This is an unfortunate side effect of the fact that OEXInterface starts as a singleton
// and immediately initializes itself in the background.
// Eventually we should fix that.
- (UIApplicationState)applicationState {
    return UIApplicationStateActive;
}

- (UIUserInterfaceLayoutDirection) userInterfaceLayoutDirection {
    return UIUserInterfaceLayoutDirectionLeftToRight;
}

@end

@interface OEXPushNotificationManagerTests : XCTestCase

@property (strong, nonatomic) OEXPushSettingsManager* settingsManager;
@property (strong, nonatomic) OEXPushNotificationManager* manager;
@property (strong, nonatomic) OEXSession* session;
@property (strong, nonatomic) id provider;
@property (strong, nonatomic) OCMockObject* applicationClassMock;
@property (strong, nonatomic) OEXMockApplicationNotifications* applicationInstanceMock;

@end

@implementation OEXPushNotificationManagerTests

- (void)setUp {
    self.settingsManager = [[OEXPushSettingsManager alloc] init];
    self.manager = [[OEXPushNotificationManager alloc] initWithSettingsManager:self.settingsManager];
    self.session = [[OEXSession alloc] initWithCredentialStore:[[OEXMockCredentialStorage alloc] init]];
    self.provider = OCMStrictProtocolMock(@protocol(OEXPushProvider));
    self.applicationClassMock = OCMStrictClassMock([UIApplication class]);
    self.applicationInstanceMock = [[OEXMockApplicationNotifications alloc] init];
    id stub = [self.applicationClassMock stub];
    [stub sharedApplication];
    [stub andReturn:self.applicationInstanceMock];
}

- (void)tearDown {
    [self.applicationClassMock stopMocking];
    self.manager = nil;
    self.session = nil;
    self.provider = nil;
}

- (void)testProviderRoutingRegistrationSuccess {
    [self.manager addProvider:self.provider withSession:self.session];
    
    NSData* token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];
    [[self.provider expect] didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    [self.manager didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    OCMVerifyAll(self.provider);
    XCTAssertFalse(self.applicationInstanceMock.registered);
}

- (void)testProviderRoutingRegistrationFailure {
    [self.manager addProvider:self.provider withSession:self.session];
    
    NSError* error = [[NSError alloc] initWithDomain:@"error" code:2 userInfo:@{}];
    [[self.provider expect] didFailToRegisterForRemoteNotificationsWithError:error];
    
    [self.manager didFailToRegisterForRemoteNotificationsWithError:error];
    
    OCMVerifyAll(self.provider);
    XCTAssertFalse(self.applicationInstanceMock.registered);
}

- (void)testProviderSessionStartsBeforeSetup {
    
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    OEXUserDetails* userDetails = [[OEXUserDetails alloc] init];
    [self.session saveAccessToken:token userDetails:userDetails];
    
    [[self.provider expect] sessionStartedWithUserDetails:userDetails settingsManager:self.settingsManager];
    
    [self.manager addProvider:self.provider withSession:self.session];
    
    OCMVerifyAll(self.provider);
    XCTAssertTrue(self.applicationInstanceMock.registered);
}

- (void)testProviderSessionStartsAfterSetup {
    [self.manager addProvider:self.provider withSession:self.session];
    
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    OEXUserDetails* userDetails = [[OEXUserDetails alloc] init];
    
    [[self.provider expect] sessionStartedWithUserDetails:userDetails settingsManager:self.settingsManager];
    
    [self.session saveAccessToken:token userDetails:userDetails];
    
    OCMVerifyAll(self.provider);
    XCTAssertTrue(self.applicationInstanceMock.registered);
}

- (void)testProviderSessionEnds {
    [self.manager addProvider:self.provider withSession:self.session];

    [[self.provider expect] sessionEnded];

    [self.session closeAndClearSession];

    OCMVerifyAll(self.provider);
}

- (void)testListenerAdd {
    NSDictionary* userInfo = @{@"thing" : @"happened"};
    
    id listener = OCMStrictProtocolMock(@protocol(OEXPushListener));
    [[listener expect] didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    [self.manager addListener:listener];
    [self.manager didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    OCMVerifyAll(listener);
}

- (void)testListenerRemove {
    NSDictionary* userInfo = @{@"thing" : @"happened"};
    
    id listener = OCMStrictProtocolMock(@protocol(OEXPushListener));
    [[listener reject] didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    [self.manager addListener:listener];
    [self.manager removeListener:listener];
    [self.manager didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    OCMVerifyAll(listener);
}

@end
