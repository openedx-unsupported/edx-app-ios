//
//  OEXPushNotificationManager.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Parse/Parse.h>

#import "OEXPushNotificationManager.h"

#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXConfig.h"
#import "OEXParseConfig.h"
#import "OEXPushListener.h"
#import "OEXParsePushProvider.h"
#import "OEXPushSettingsManager.h"
#import "OEXSession.h"

@interface OEXPushNotificationManager ()

@property (strong, nonatomic) NSMutableArray* providers;
@property (strong, nonatomic) NSMutableArray* listeners;
@property (copy, nonatomic) void (^registrationAction)(void);

@property (strong, nonatomic) OEXPushSettingsManager* settingsManager;

@end

@implementation OEXPushNotificationManager

- (id)initWithSettingsManager:(OEXPushSettingsManager*)settingsManager {
    self = [super init];
    NSAssert(settingsManager != nil, @"Requires valid settings manager");
    if(self != nil) {
        self.providers = [[NSMutableArray alloc] init];
        self.listeners = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionStartedNotification action:^(NSNotification *notification, OEXPushNotificationManager* observer, id<OEXRemovable> removable) {
            OEXUserDetails* userDetails = notification.userInfo[OEXSessionStartedUserDetailsKey];
            [observer sessionStartedWithUserDetails:userDetails];
        }];

        [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionEndedNotification action:^(NSNotification *notification, id observer, id<OEXRemovable> removable) {
            [observer sessionEnded];
        }];
        self.settingsManager = settingsManager;
    }
    return self;
}

- (void)performRegistration {
    UIApplication* application = [UIApplication sharedApplication];
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet set]];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
}

- (void)addListener:(id<OEXPushListener>)listener {
    [self.listeners addObject:listener];
}

- (void)removeListener:(id <OEXPushListener>)listener {
    [self.listeners removeObject:listener];
}

- (void)addProvider:(id <OEXPushProvider>)provider withSession:(OEXSession *)session {
    [self.providers addObject:provider];
    if(session.currentUser != nil) {
        [provider sessionStartedWithUserDetails:session.currentUser settingsManager:self.settingsManager];
    }
}

- (void)addProvidersForConfiguration:(OEXConfig *)config withSession:(OEXSession *)session {
    OEXParseConfig* parseConfig = config.parseConfig;
    if(parseConfig.notificationsEnabled) {
        [Parse setApplicationId:parseConfig.applicationID clientKey:parseConfig.clientKey];
        OEXParsePushProvider* provider = [[OEXParsePushProvider alloc] init];
        [self addProvider:provider withSession:session];
    }
}

- (void)sessionStartedWithUserDetails:(OEXUserDetails*)userDetails {
    for(id <OEXPushProvider> provider in self.providers) {
        [provider sessionStartedWithUserDetails:userDetails settingsManager:self.settingsManager];
    }

    [self performRegistration];
}

- (void)sessionEnded {
    for(id <OEXPushProvider> provider in self.providers) {
        [provider sessionEnded];
    }
}

- (void)didReceiveLocalNotificationWithUserInfo:(NSDictionary *)userInfo {
    for(id<OEXPushListener> listener in self.listeners) {
        [listener didReceiveLocalNotificationWithUserInfo:userInfo];
    }
}

- (void)didReceiveRemoteNotificationWithUserInfo:(NSDictionary *)userInfo {
    for(id <OEXPushListener> listener in self.listeners) {
        [listener didReceiveRemoteNotificationWithUserInfo:userInfo];
    }
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    for(id <OEXPushProvider> provider in self.providers) {
        [provider didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    for(id <OEXPushProvider> provider in self.providers) {
        [provider didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

@end
