//
//  OEXPushNotificationManager.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXPushNotificationManager.h"

#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXConfig.h"
#import "OEXPushListener.h"
#import "OEXPushSettingsManager.h"
#import "OEXSession.h"
#import "edX-Swift.h"

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

    UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
    }];

    [application registerForRemoteNotifications];
}

- (void)addListener:(id<OEXPushListener>)listener {
    [self.listeners addObject:listener];
}

- (void)removeListener:(id <OEXPushListener>)listener {
    [self.listeners removeObject:listener];
}

- (void)addListenersForConfiguration:(OEXConfig *)config environment:(RouterEnvironment *)environment {
    if ([[config firebaseConfig] cloudMessagingEnabled]) {
        FCMListner *listner = [[FCMListner alloc] initWithEnvironment:environment];
        [self addListener:listner];
    }
}

- (void)addProvider:(id <OEXPushProvider>)provider withSession:(OEXSession *)session {
    [self.providers addObject:provider];
    if(session.currentUser != nil) {
        [provider sessionStartedWithUserDetails:session.currentUser settingsManager:self.settingsManager];
    }
}

- (void)addProvidersForConfiguration:(OEXConfig *)config withSession:(OEXSession *)session {
    if ([[config firebaseConfig] cloudMessagingEnabled]){
        FCMProvider *provide = [[FCMProvider alloc] init];
        [self addProvider:provide withSession:session];
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
