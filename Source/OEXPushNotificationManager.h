//
//  OEXPushProviderRegistry.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
NS_ASSUME_NONNULL_BEGIN

@class OEXConfig;
@class OEXSession;
@class OEXPushSettingsManager;
@protocol OEXPushListener;
@protocol OEXPushProvider;
@class RouterEnvironment;

@interface OEXPushNotificationManager : NSObject <UNUserNotificationCenterDelegate>

/// Will use the passed action to register for push notifications. Passing a custom registration
/// action makes it easy to mock for tests.
- (id)initWithSettingsManager:(OEXPushSettingsManager*)settingsManager;

- (void)addProvider:(id <OEXPushProvider>)provider withSession:(OEXSession*)session;
- (void)addProvidersForConfiguration:(OEXConfig*)config withSession:(OEXSession*)session;

- (void)addListener:(id <OEXPushListener>)listener;
- (void)addListenersForConfiguration:(OEXConfig *)config environment:(RouterEnvironment *)environment;
- (void)removeListener:(id <OEXPushListener>)listener;

- (void)didReceiveLocalNotificationWithUserInfo:(NSDictionary*)userInfo;
- (void)didReceiveRemoteNotificationWithUserInfo:(NSDictionary*)userInfo;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;

@end

NS_ASSUME_NONNULL_END
