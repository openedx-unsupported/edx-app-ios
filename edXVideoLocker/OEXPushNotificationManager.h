//
//  OEXPushProviderRegistry.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXConfig;
@class OEXSession;
@protocol OEXPushProvider;


@interface OEXPushNotificationManager : NSObject

/// Will use the passed action to register for push notifications
- (id)initWithRegistrationAction:(void(^)(void))registrationAction NS_DESIGNATED_INITIALIZER;
/// Convience for initWithRegistrationAction: that effectfully registers via UIApplication
- (id)init;

- (void)addProvider:(id <OEXPushProvider>)provider withSession:(OEXSession*)session;
- (void)addProvidersForConfiguration:(OEXConfig*)config withSession:(OEXSession*)session;

- (void)didReceiveRemoteNotificationWithUserInfo:(NSDictionary*)userInfo;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;

@end
