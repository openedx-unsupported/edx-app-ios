//
//  OEXPushProvider.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OEXPushSettingsManager;
@class OEXUserDetails;

@protocol OEXPushProvider <NSObject>

- (void)sessionStartedWithUserDetails:(OEXUserDetails*)user settingsManager:(OEXPushSettingsManager*)settingsManager;
- (void)sessionEnded;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)device;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;

@end

NS_ASSUME_NONNULL_END
